from pathlib import Path
import subprocess,time,re,sys,os
root=Path(__file__).resolve().parent
variant=sys.argv[1] if len(sys.argv)>1 else 'A'
def adb(*a):return subprocess.check_output(['adb',*a],text=True)
pkg='dev.artflutter.element_cache_bench'
adb('install','-r',str(root/variant/'app/build/app/outputs/flutter-apk/app-profile.apk'))
adb('shell','am','force-stop',pkg)
log=root/('profile-'+variant+'.log')
with log.open('w') as out:
 p=subprocess.Popen(['adb','logcat','-T','1','-v','raw','-s','flutter:I'],stdout=out)
 adb('shell','am','start','-W','-n',pkg+'/.MainActivity')
 try:
  for _ in range(100):
   text=log.read_text();m=re.search(r'Dart VM service is listening on http://127.0.0.1:(\d+)/(\S+)',text)
   if m:break
   time.sleep(.1)
  else:raise RuntimeError(text)
  port=adb('forward','tcp:0','tcp:'+m[1]).strip()
  subprocess.run(['dart','--packages='+os.environ['DART_PACKAGES'],str(root/'profile.dart'),f'ws://127.0.0.1:{port}/{m[2]}ws',str(root/('profile-'+variant+'.json'))],check=True)
 finally:
  adb('shell','am','force-stop',pkg);p.terminate();p.wait()
print(log.read_text()[-1200:])
