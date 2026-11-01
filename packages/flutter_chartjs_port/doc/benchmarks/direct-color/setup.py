"""Reconstruct the isolated direct-color Android experiment from the pinned tree."""
from pathlib import Path
import argparse
import io
import shutil
import subprocess
import tarfile

BASE = '175337ff09d37b6aa7a5de76cdf5f90e44be6bc8'
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--repo', type=Path, required=True)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
repo = args.repo.resolve()
out = args.out.resolve()
evidence = Path(__file__).resolve().parent
out.mkdir(parents=True, exist_ok=True)
if any(out.iterdir()):
    raise SystemExit('--out must be an empty directory')
archive = subprocess.check_output([
    'git', '-C', str(repo), 'archive', BASE,
    'packages/flutter_chartjs_port/lib',
    'packages/flutter_chartjs_port/pubspec.yaml',
    'apps/chartjs_gallery/lib', 'apps/chartjs_gallery/android',
])
snapshot = out / 'snapshot'
with tarfile.open(fileobj=io.BytesIO(archive)) as tar:
    tar.extractall(snapshot, filter='data')
port = out / 'port'
app = out / 'app'
shutil.move(snapshot / 'packages/flutter_chartjs_port', port)
app.mkdir()
for name in ['lib', 'android']:
    shutil.move(snapshot / 'apps/chartjs_gallery' / name, app / name)
shutil.rmtree(snapshot)
pubspec = port / 'pubspec.yaml'
pubspec.write_text(pubspec.read_text().split('dev_dependencies:')[0].replace('resolution: workspace\n', ''))
(app / 'pubspec.yaml').write_text('''name: chartjs_gallery
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
for path in (app / 'android').rglob('*'):
    if path.is_file() and path.suffix in ('.kts', '.kt', '.xml'):
        path.write_text(path.read_text().replace(
            'dev.artflutter.chartjs_gallery', 'dev.artflutter.direct_color_bench'))
subprocess.run(['patch', '-p1', '-i', str(evidence / 'candidate.patch')], cwd=port, check=True)
for name in ['main_direct_color.dart', 'main_common_color.dart']:
    shutil.copy2(evidence / (name + '.txt'), app / 'lib' / name)
for name in ['build.py', 'run_android.py', 'report.py']:
    shutil.copy2(evidence / name, out / name)
if (evidence / 'pubspec.lock').exists():
    shutil.copy2(evidence / 'pubspec.lock', app / 'pubspec.lock')
(out / 'artifacts').mkdir()
(out / 'runs').mkdir()
print('Prepared:', out)
print('Next: flutter pub get --offline in app/, then python3 build.py A B in the output directory.')
