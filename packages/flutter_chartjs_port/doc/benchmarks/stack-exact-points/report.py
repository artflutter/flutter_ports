from pathlib import Path
import json,statistics,gzip,sys
r=Path(__file__).resolve().parent
rows=[]
if '--recorded' in sys.argv:
 runs=json.loads(gzip.decompress((r/'measurements.json.gz').read_bytes()))
else:runs=[json.loads(p.read_text()) for platform in ['macos','chrome'] for p in sorted((r/platform).glob('*.json'))]
for platform in ['macos','chrome-wasm']:
 groups={}
 for run in runs:
  if run['platform']!=platform:continue
  for row in run['rows']:
   key=(row['experimentCase'],row['n'],row['call'])
   value=sum(float(row.get(k+'MedianMs',0)) for k in ['update','draw','end'])
   groups.setdefault(key,{'A':[],'B':[]})[run['variant']].append(value)
 for (case,n,call),ab in groups.items():
  if not all(ab.values()):continue
  a,b=[statistics.median(ab[v]) for v in ['A','B']]
  row={'platform':platform,'case':case,'n':n,'call':call,'A_ms':a,'B_ms':b,'reduction_pct':100*(1-b/a),'runs':ab}
  rows.append(row)
  print(f'{platform:12} {case:12} N{n:4} {call:6}: {a:.4f} -> {b:.4f} ms, {100*(1-b/a):+.1f}% saved; {ab}')
(r/'summary.json').write_text(json.dumps(rows,indent=2)+'\n')
