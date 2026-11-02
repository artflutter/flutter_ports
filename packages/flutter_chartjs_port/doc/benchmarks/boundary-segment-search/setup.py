"""Reconstruct both Android benchmark sources in an empty output directory."""
from pathlib import Path
import argparse,io,json,shutil,subprocess,tarfile
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--repo',type=Path,required=True)
parser.add_argument('--out',type=Path,required=True)
args=parser.parse_args();repo=args.repo.resolve();out=args.out.resolve();evidence=Path(__file__).resolve().parent
out.mkdir(parents=True,exist_ok=True)
if any(out.iterdir()):raise SystemExit('--out must be empty')
metadata=json.loads((evidence/'metadata.json').read_text())
archive=subprocess.check_output(['git','-C',str(repo),'archive',metadata['baseline'],'packages/flutter_chartjs_port/lib','packages/flutter_chartjs_port/pubspec.yaml','apps/chartjs_gallery/lib','apps/chartjs_gallery/android'])
for variant in ['A','B']:
 d=out/variant;d.mkdir()
 with tarfile.open(fileobj=io.BytesIO(archive)) as tar:tar.extractall(d,filter='data')
 shutil.move(d/'packages/flutter_chartjs_port',d/'port');shutil.move(d/'apps/chartjs_gallery',d/'app')
 shutil.rmtree(d/'packages');shutil.rmtree(d/'apps')
 p=d/'port/pubspec.yaml';p.write_text(p.read_text().split('dev_dependencies:')[0].replace('resolution: workspace\n',''))
 (d/'app/pubspec.yaml').write_text('''name: chartjs_gallery
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
 for p in (d/'app/android').rglob('*'):
  if p.is_file() and p.suffix in ['.kts','.kt','.xml']:
   p.write_text(p.read_text().replace('dev.artflutter.chartjs_gallery','dev.artflutter.gap_fill_bench'))
 shutil.copy2(evidence/'pubspec.lock',d/'app/pubspec.lock')
 shutil.copy2(evidence/'main_gap.dart.txt',d/'app/lib/main_gap.dart')
 if variant=='B':subprocess.run(['patch','-p1','-i',str(evidence/'candidate.patch')],cwd=d/'port',check=True)
for name in ['run_android.py','profile.py','build.py']:shutil.copy2(evidence/name,out/name)
shutil.copy2(evidence/'profile.dart.txt',out/'profile.dart')
(out/'artifacts').mkdir()
print('Prepared',out)
