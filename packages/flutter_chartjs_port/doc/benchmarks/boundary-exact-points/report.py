"""Recompute the recorded CPU comparison without an Android device."""
from pathlib import Path
import gzip,json,statistics
root=Path(__file__).resolve().parent
runs=json.loads(gzip.decompress((root/'measurements.json.gz').read_bytes()))
groups={}
for run in runs:
 for row in run['rows']:
  key=(row['experimentCase'],row['n'],row['call'])
  value=sum(float(row.get(metric+'MedianMs',0)) for metric in ['update','draw','end'])
  groups.setdefault(key,{'A':[],'B':[]})[run['variant']].append(value)
summary=[]
for (case,n,call),values in groups.items():
 a,b=(statistics.median(values[v]) for v in ['A','B'])
 pairs=[100*(1-bv/av) for av,bv in zip(values['A'],values['B'])]
 row={'case':case,'n':n,'call':call,'baseline_ms':a,'candidate_ms':b,'change_ms':b-a,'saved_percent':100*(1-b/a),'paired_saved_percent':pairs,'process_values':values}
 summary.append(row)
 print(f'{case:12} {n:4} {call:6} {a:.4f} -> {b:.4f} ms ({row["saved_percent"]:+.2f}% saved)')
(root/'summary.json').write_text(json.dumps(summary,indent=2)+'\n')
