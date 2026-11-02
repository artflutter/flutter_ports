"""Build isolated arm64 release APKs, one at a time."""
from pathlib import Path
import shutil,subprocess,sys
root=Path(__file__).resolve().parent
for variant in sys.argv[1:]:
 if variant not in ['A','B']:raise SystemExit('Expected A or B')
 app=root/variant/'app'
 subprocess.run(['flutter','pub','get','--offline'],cwd=app,check=True)
 subprocess.run(['flutter','build','apk','--release','--target-platform','android-arm64','-t','lib/main_cache.dart','--dart-define=VARIANT='+variant],cwd=app,check=True)
 shutil.copy2(app/'build/app/outputs/flutter-apk/app-release.apk',root/'artifacts'/(variant+'.apk'))
