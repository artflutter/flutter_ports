"""Reconstruct the measured stack-search experiment outside the repository."""
from pathlib import Path
import argparse,io,shutil,subprocess,tarfile
BASE='3ea45085a961adc2fc50770294d6cce04417ac2d'
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--repo',type=Path,required=True);p.add_argument('--out',type=Path,required=True)
a=p.parse_args();repo=a.repo.resolve();out=a.out.resolve();evidence=Path(__file__).resolve().parent
out.mkdir(parents=True,exist_ok=True)
if any(out.iterdir()):raise SystemExit('--out must be empty')
archive=subprocess.check_output(['git','-C',str(repo),'archive',BASE,'packages/flutter_chartjs_port/lib','packages/flutter_chartjs_port/pubspec.yaml','apps/chartjs_gallery/lib','apps/chartjs_gallery/macos','apps/chartjs_gallery/web'])
for v in ['A','B','C']:
 d=out/v;temp=d/'snapshot';temp.mkdir(parents=True)
 with tarfile.open(fileobj=io.BytesIO(archive)) as t:t.extractall(temp,filter='data')
 shutil.move(temp/'packages/flutter_chartjs_port',d/'port');shutil.move(temp/'apps/chartjs_gallery',d/'app');shutil.rmtree(temp)
 path=d/'port/pubspec.yaml';path.write_text(path.read_text().split('dev_dependencies:')[0].replace('resolution: workspace\n',''))
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
 if v in ['B','C']:
  patch=evidence.parent/'candidate.patch' if v=='B' else evidence/'candidate.patch'
  subprocess.run(['patch','-p1','-i',str(patch)],cwd=d/'port',check=True)
 for name in ['main_stack_guardfirst.dart','main_stack_diagnostic.dart','bench_done.dart','bench_done_native.dart','bench_done_web.dart']:
  shutil.copy2(evidence/(name+'.txt'),d/'app/lib'/name)
 shutil.copy2(evidence/'pubspec.lock',d/'app/pubspec.lock')
for name in ['build.py','run_macos_final.py','run_chrome_final.py','run_isolated_gaps.py','report.py']:shutil.copy2(evidence/name,out/name)
print('Prepared',out)
