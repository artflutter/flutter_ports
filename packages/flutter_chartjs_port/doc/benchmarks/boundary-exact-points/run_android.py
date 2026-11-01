from pathlib import Path
import subprocess,time,json,hashlib,sys,re
root=Path(__file__).resolve().parent;raw=root/'runs';raw.mkdir(exist_ok=True)
pkg='dev.artflutter.gap_fill_bench'
def adb(*args):return subprocess.check_output(['adb','-s','4B071JEKB17363',*args],text=True)
for name in sys.argv[1:]:
 tag=f'{len(list(raw.glob("*.state.json"))):03d}-{name}';log=raw/(tag+'.log')
 state={'variant':name,'start':time.time(),'batteryBefore':adb('shell','dumpsys','battery')}
 for attempt in range(41):
  temp=int(re.search(r'temperature: (\d+)',state['batteryBefore'])[1])
  if temp<=340:break
  if attempt==40:raise RuntimeError('Cooling timeout')
  print('Cooling',temp/10,flush=True);time.sleep(15)
  state['batteryBefore']=adb('shell','dumpsys','battery')
 state['thermalBefore']=adb('shell','dumpsys','thermalservice')
 apk=root/'artifacts'/(name+'.apk');state['apkSha256']=hashlib.sha256(apk.read_bytes()).hexdigest()
 adb('install','-r',str(apk));adb('shell','am','force-stop',pkg)
 adb('shell','am','start','-W','-n',pkg+'/.MainActivity');pid=adb('shell','pidof',pkg).strip();state['pid']=pid
 with log.open('w') as out:
  proc=subprocess.Popen(['adb','-s','4B071JEKB17363','logcat','--pid='+pid,'-v','raw','-s','flutter:I'],stdout=out,stderr=subprocess.STDOUT)
  started=time.time();done=False
  try:
   while time.time()-started<120:
    content=log.read_text(errors='replace')
    if 'GAP_DONE '+name in content:done=True;break
    if 'GAP_ERROR' in content:break
    time.sleep(.5)
  finally:
   adb('shell','am','force-stop',pkg);proc.terminate();proc.wait()
 rows=[json.loads(line[len('GAP_RESULT '):]) for line in log.read_text().splitlines() if line.startswith('GAP_RESULT ')]
 state.update(complete=done,rows=len(rows),batteryAfter=adb('shell','dumpsys','battery'),thermalAfter=adb('shell','dumpsys','thermalservice'))
 (raw/(tag+'.json')).write_text(json.dumps(rows,indent=2)+'\n');(raw/(tag+'.state.json')).write_text(json.dumps(state,indent=2)+'\n')
 print(tag,done,len(rows),re.search(r'temperature: (\d+)',state['batteryAfter'])[1],flush=True)
 if not done or len(rows)!=10:raise RuntimeError('Incomplete '+tag)
 time.sleep(10)
