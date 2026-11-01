from pathlib import Path
import subprocess,sys
root=Path(__file__).resolve().parent
for v in sys.argv[1:]:
 app=root/v/'app'
 for platform in ['macos','apk']:
  args=['flutter','build',platform,'--release','-t','lib/main_color_bench.dart','--dart-define=VARIANT='+v]
  if platform=='apk':args+=['--target-platform','android-arm64']
  with (root/f'build-{v}-{platform}.log').open('w') as log:
   subprocess.run(args,cwd=app,stdout=log,stderr=subprocess.STDOUT,check=True)
  print('Built',v,platform,flush=True)
