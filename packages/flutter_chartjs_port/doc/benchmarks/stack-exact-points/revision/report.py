from pathlib import Path
import json,gzip,statistics,sys
root=Path(__file__).resolve().parent
if '--recorded' in sys.argv:
 runs=json.loads(gzip.decompress((root/'measurements.json.gz').read_bytes()))
else:
 runs=[json.loads(p.read_text()) for folder in ['macos-final','chrome-final'] for p in sorted((root/folder).glob('*.json'))]
rows=[]
for platform in ['macos','chrome']:
 groups={}
 for run in runs:
  if run['platform'].split('-')[0]!=platform:continue
  for cell in run['rows']:
   key=(cell['experimentCase'],cell['n'],cell['call'])
   groups.setdefault(key,{'A':[],'C':[]})[run['variant']].append(sum(float(cell.get(k+'MedianMs',0)) for k in ['update','draw','end']))
 for (case,n,call),values in groups.items():
  a,c=[statistics.median(values[v]) for v in ['A','C']]
  rows.append({'platform':platform,'case':case,'n':n,'call':call,'baseline_ms':a,'candidate_ms':c,'change_ms':c-a,'reduction_pct':100*(1-c/a),'runs':values})
  print(f'{platform} {case} {n} {call}: {a:.4f} -> {c:.4f} ms ({100*(1-c/a):+.2f}% saved)')
(root/'summary.json').write_text(json.dumps(rows,indent=2)+'\n')
