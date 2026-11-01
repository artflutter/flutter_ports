from pathlib import Path
import subprocess,time,json,hashlib,sys,re,threading,os
root=Path(__file__).resolve().parent; raw=root/os.environ.get('RUN_DIR','runs'); raw.mkdir(exist_ok=True)
dev='4B071JEKB17363';pkg='dev.artflutter.direct_color_bench'
def adb(*args):
 return subprocess.run(['adb','-s',dev,*args],check=True,text=True,capture_output=True).stdout
for name in sys.argv[1:]:
 tag=f'{len(list(raw.glob("*.state.json"))):03d}-{name}';log=raw/(tag+'.log')
 state={'name':name,'start':time.time(),'batteryBefore':adb('shell','dumpsys','battery')}
 temp=int(re.search(r'temperature: (\d+)',state['batteryBefore']).group(1))
 ceiling=int(os.environ.get('MAX_BATTERY_TEMP','340'))
 coolingStart=time.time()
 while temp>ceiling and os.environ.get('WAIT_COOL')=='1':
  if time.time()-coolingStart>600: raise SystemExit('Cooling timeout')
  print('Cooling',temp/10,'C; target',ceiling/10,flush=True)
  time.sleep(15)
  state['batteryBefore']=adb('shell','dumpsys','battery')
  temp=int(re.search(r'temperature: (\d+)',state['batteryBefore']).group(1))
 if temp>ceiling: raise SystemExit('Battery above the configured temperature gate')
 state['start']=time.time()
 state['thermalBefore']=adb('shell','dumpsys','thermalservice')
 apk=root/'artifacts'/(name+os.environ.get('SUFFIX','')+'.apk');state['sha256']=hashlib.sha256(apk.read_bytes()).hexdigest()
 adb('install','-r',str(apk));adb('shell','am','force-stop',pkg)
 adb('shell','am','start','-W','-n',pkg+'/.MainActivity');pid=adb('shell','pidof',pkg).strip();state['pid']=pid
 with log.open('w') as out:
  proc=subprocess.Popen(['adb','-s',dev,'logcat','--pid='+pid,'-v','raw','-s','flutter:I'],stdout=out,stderr=subprocess.STDOUT)
  started=time.time();done=False
  while time.time()-started<100:
   contents=log.read_text(errors='replace')
   if 'DIRECT_DONE '+name in contents:done=True;break
   if 'DIRECT_ERROR' in contents:break
   time.sleep(.5)
  adb('shell','am','force-stop',pkg);proc.terminate();proc.wait()
 rows=[]
 for line in log.read_text().splitlines():
  if line.startswith('DIRECT '): rows.append(json.loads(line[7:]))
 state.update(complete=done,rows=len(rows),batteryAfter=adb('shell','dumpsys','battery'),thermalAfter=adb('shell','dumpsys','thermalservice'))
 (raw/(tag+'.json')).write_text(json.dumps(rows,indent=2));(raw/(tag+'.state.json')).write_text(json.dumps(state,indent=2))
 print(tag,done,len(rows),flush=True)
 if not done or len(rows)!=int(os.environ.get('EXPECTED_ROWS','35')): raise SystemExit('Incomplete '+str(log))
 time.sleep(10)
