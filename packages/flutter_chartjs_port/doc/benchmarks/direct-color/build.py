from pathlib import Path
import subprocess,shutil,sys,os
root=Path(__file__).resolve().parent
suffix=os.environ.get('SUFFIX','')
target=os.environ.get('TARGET','lib/main_direct_color.dart')
for name in sys.argv[1:]:
 with (root/f'build-{name}{suffix}.log').open('w') as log:
  subprocess.run(['flutter','build','apk','--release','--target-platform','android-arm64','-t',target,'--dart-define=DIRECT_COLOR='+str(name=='B').lower()],cwd=root/'app',stdout=log,stderr=subprocess.STDOUT,check=True)
 shutil.copy2(root/'app/build/app/outputs/flutter-apk/app-release.apk',root/f'artifacts/{name}{suffix}.apk')
 print('Built',name,flush=True)
