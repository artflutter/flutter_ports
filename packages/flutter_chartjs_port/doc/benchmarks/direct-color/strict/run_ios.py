from pathlib import Path
import subprocess,time,json,hashlib
root=Path(__file__).resolve().parent;out=root/'ios';out.mkdir(exist_ok=True)
device='00008150-001870922140401C'
completed=len(list(out.glob('[0-9][0-9]-[AB].json')))
for v in ['A','B','B','A'][completed:]:
 tag=f'{len(list(out.glob("[0-9][0-9]-[AB].json"))):02d}-{v}'
 runid=tag+'-'+str(time.time_ns())
 app=root/v/'app/build/ios/iphoneos/Runner.app'
 install=subprocess.run(['xcrun','devicectl','device','install','app','--device',device,str(app)],capture_output=True,text=True,timeout=60)
 assert install.returncode==0,install.stdout+install.stderr
 sentinel=out/'pending.json';sentinel.write_text(json.dumps({'pending':runid}))
 cleared=subprocess.run(['xcrun','devicectl','device','copy','to','--device',device,'--domain-type','appDataContainer','--domain-identifier','dev.artflutter.colorBench','--source',str(sentinel),'--destination','tmp/color-results-manual.json'],capture_output=True,text=True,timeout=15)
 assert cleared.returncode==0,cleared.stdout+cleared.stderr
 launch=subprocess.run(['xcrun','devicectl','device','process','launch','--device',device,'--terminate-existing','dev.artflutter.colorBench'],capture_output=True,text=True,timeout=30)
 (out/(tag+'.log')).write_text(install.stdout+install.stderr+launch.stdout+launch.stderr)
 assert launch.returncode==0,launch.stdout+launch.stderr
 dest=out/(tag+'.result')
 start=time.monotonic()
 while time.monotonic()-start<90:
  time.sleep(3)
  copied=subprocess.run(['xcrun','devicectl','device','copy','from','--device',device,'--domain-type','appDataContainer','--domain-identifier','dev.artflutter.colorBench','--source','tmp/color-results-manual.json','--destination',str(dest)],capture_output=True,text=True,timeout=15)
  if copied.returncode==0:
   rows=json.loads(dest.read_text())
   if isinstance(rows,list) and len(rows)==10:break
 else:raise RuntimeError('No completion file: '+copied.stdout+copied.stderr)
 rows=json.loads(dest.read_text())
 assert isinstance(rows,list) and len(rows)==10 and all(r['build']=='release' and r['variant']==v for r in rows),rows
 (out/(tag+'.json')).write_text(json.dumps({'variant':v,'platform':'ios','runId':runid,'sha256':hashlib.sha256((app/'Frameworks/App.framework/App').read_bytes()).hexdigest(),'rows':rows},indent=2))
 print('iOS',tag,'10 release cells',flush=True)
 time.sleep(4)
