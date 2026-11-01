from pathlib import Path
import subprocess,json,time,hashlib
r=Path(__file__).resolve().parent;o=r/'macos';o.mkdir(exist_ok=True)
for i,v in enumerate(['A','B','B','A']):
 exe=r/v/'app/build/macos/Build/Products/Release/chartjs_gallery.app/Contents/MacOS/chartjs_gallery'
 p=subprocess.run([str(exe)],capture_output=True,text=True,timeout=90)
 log=p.stdout+'\n'+p.stderr;(o/f'{i:02d}-{v}.log').write_text(log)
 rows=[json.loads(x.split('STACK_RESULT ',1)[1]) for x in log.splitlines() if 'STACK_RESULT ' in x]
 assert len(rows)==10 and all(x['build']=='release' for x in rows),log[-3000:]
 (o/f'{i:02d}-{v}.json').write_text(json.dumps({'variant':v,'platform':'macos','sha256':hashlib.sha256(exe.read_bytes()).hexdigest(),'rows':rows},indent=2))
 print('macOS',i,v,'10 cells',flush=True);time.sleep(4)
