from pathlib import Path
import subprocess
root=Path(__file__).resolve().parent
for variant in ['A','C']:
 with (root/f'build-{variant}.log').open('w') as log:
  for command in [['flutter','pub','get','--offline'],['flutter','build','macos','--release','-t','lib/main_stack_guardfirst.dart','--dart-define=VARIANT='+variant]]:
   subprocess.run(command,cwd=root/variant/'app',stdout=log,stderr=subprocess.STDOUT,check=True)
 print('Built',variant,flush=True)
