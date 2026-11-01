from pathlib import Path
import subprocess,sys,time,json,re,hashlib
root=Path(__file__).resolve().parent
platform=sys.argv[1];out=root/platform;out.mkdir(exist_ok=True)
pkg='dev.artflutter.direct_color_production'
def adb(*args):return subprocess.check_output(['adb','-s','4B071JEKB17363',*args],text=True)
for v in ['A','B','B','A']:
 tag=f'{len(list(out.glob("*.json"))):02d}-{v}';meta={'variant':v,'platform':platform}
 if platform=='macos':
  exe=root/v/'app/build/macos/Build/Products/Release/chartjs_gallery.app/Contents/MacOS/chartjs_gallery'
  meta['sha256']=hashlib.sha256(exe.read_bytes()).hexdigest()
  p=subprocess.run([str(exe)],capture_output=True,text=True,timeout=90)
  log=p.stdout+'\n'+p.stderr
 else:
  meta['batteryBefore']=adb('shell','dumpsys','battery')
  apk=root/v/'app/build/app/outputs/flutter-apk/app-release.apk'
  meta['sha256']=hashlib.sha256(apk.read_bytes()).hexdigest()
  adb('install','-r',str(apk));adb('shell','am','force-stop',pkg)
  adb('shell','am','start','-W','-n',pkg+'/.MainActivity')
  pid=adb('shell','pidof',pkg).strip()
  with (out/(tag+'.log')).open('w') as sink:
   proc=subprocess.Popen(['adb','-s','4B071JEKB17363','logcat','--pid='+pid,'-v','raw','-s','flutter:I'],stdout=sink,stderr=subprocess.STDOUT)
   start=time.time()
   while time.time()-start<90:
    log=(out/(tag+'.log')).read_text()
    if 'COLOR_DONE' in log or 'COLOR_ERROR' in log:break
    time.sleep(.5)
   proc.terminate();proc.wait()
  adb('shell','am','force-stop',pkg)
  meta['batteryAfter']=adb('shell','dumpsys','battery')
 rows=[]
 for line in log.splitlines():
  if 'COLOR_RESULT ' in line:rows.append(json.loads(line.split('COLOR_RESULT ',1)[1]))
 (out/(tag+'.log')).write_text(log)
 meta['rows']=rows
 (out/(tag+'.json')).write_text(json.dumps(meta,indent=2))
 assert len(rows)==10 and all(r['build']=='release' for r in rows),log[-3000:]
 print(platform,tag,'10 release cells',flush=True)
 time.sleep(4)
