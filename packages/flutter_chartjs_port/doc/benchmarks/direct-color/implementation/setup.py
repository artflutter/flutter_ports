"""Reconstruct baseline and implementation benchmark apps without editing the repo."""
from pathlib import Path
import argparse,io,shutil,subprocess,tarfile
BASE='175337ff09d37b6aa7a5de76cdf5f90e44be6bc8'
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--repo',type=Path,required=True)
p.add_argument('--out',type=Path,required=True)
a=p.parse_args();repo=a.repo.resolve();out=a.out.resolve();evidence=Path(__file__).resolve().parent
out.mkdir(parents=True,exist_ok=True)
if any(out.iterdir()):raise SystemExit('--out must be empty')
archive=subprocess.check_output(['git','-C',str(repo),'archive',BASE,'packages/flutter_chartjs_port/lib','packages/flutter_chartjs_port/pubspec.yaml','apps/chartjs_gallery/lib','apps/chartjs_gallery/android','apps/chartjs_gallery/macos','apps/chartjs_gallery/web'])
for v in ['A','B']:
 base=out/v;snapshot=base/'snapshot'
 with tarfile.open(fileobj=io.BytesIO(archive)) as tar:tar.extractall(snapshot,filter='data')
 port=base/'port';app=base/'app'
 shutil.move(snapshot/'packages/flutter_chartjs_port',port)
 shutil.move(snapshot/'apps/chartjs_gallery',app)
 shutil.rmtree(snapshot)
 path=port/'pubspec.yaml';path.write_text(path.read_text().split('dev_dependencies:')[0].replace('resolution: workspace\n',''))
 (app/'pubspec.yaml').write_text('''name: chartjs_gallery
publish_to: none
version: 1.0.0+1
environment:
  sdk: ^3.13.0
dependencies:
  flutter:
    sdk: flutter
  flutter_chartjs_port:
    path: ../port
flutter:
  uses-material-design: true
''')
 for path in app.rglob('*'):
  if path.is_file() and path.suffix in ('.kts','.kt','.xml','.xcconfig','.pbxproj','.plist'):
   path.write_text(path.read_text().replace('dev.artflutter.chartjs_gallery','dev.artflutter.direct_color_production'))
 if v=='B':subprocess.run(['patch','-p1','-i',str(evidence/'candidate.patch')],cwd=port,check=True)
 for name in ['main_color_bench.dart','bench_done.dart','bench_done_native.dart','bench_done_web.dart']:
  shutil.copy2(evidence/(name+'.txt'),app/'lib'/name)
 shutil.copy2(evidence/'pubspec.lock',app/'pubspec.lock')
for name in ['build.py','run_native.py','run_chrome.py','report.py']:shutil.copy2(evidence/name,out/name)
print('Prepared',out)
