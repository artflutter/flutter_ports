from pathlib import Path
import json,statistics as s,gzip,sys
root=Path(__file__).resolve().parent
report=[]
for platform in ['macos','chrome','android','ios']:
 groups={}
 if '--recorded' in sys.argv:
  runs=[r for r in json.loads(gzip.decompress((root/'measurements.json.gz').read_bytes())) if r['platform'].split('-')[0]==platform]
 else:
  runs=[json.loads(p.read_text()) for p in sorted((root/platform).glob('[0-9][0-9]-[AB].json'))]
 for run in runs:
  v=run['variant']
  for r in run['rows']:
   key=(r['case'],r['call']);groups.setdefault(key,{'A':[],'B':[]})[v].append(sum(float(r.get(k+'MedianMs',0)) for k in ['update','draw','end']))
 for (case,call),ab in groups.items():
  if not all(ab.values()):continue
  a,b=[s.median(ab[v]) for v in ['A','B']]
  row={'platform':platform,'case':case,'call':call,'A_ms':a,'B_ms':b,'reduction_pct':100*(1-b/a),'runs':ab};report.append(row)
  print(f'{platform:8} {case:18} {call:6} {a:.3f} -> {b:.3f} ms ({100*(1-b/a):+.1f}% saved)')
(root/'summary.json').write_text(json.dumps(report,indent=2))
