"""Recompute every release cell, paired deltas and the predeclared decision."""
from pathlib import Path
import gzip,json,statistics
root=Path(__file__).resolve().parent
runs=json.loads(gzip.decompress((root/'measurements.json.gz').read_bytes()))
groups={}
for run in runs:
 for r in run['rows']:
  key=(r['experimentCase'],r['n'],r['call'])
  values={m:float(r.get(m+'MedianMs',0)) for m in ['update','draw','end']}
  values['total']=sum(values.values())
  groups.setdefault(key,{'A':[],'B':[]})[run['variant']].append(values)
summary=[]
for (case,n,call),values in groups.items():
 metrics={}
 for m in ['update','draw','end','total']:
  a,b=(statistics.median(v[m] for v in values[k]) for k in ['A','B'])
  metrics[m]={'baseline_ms':a,'candidate_ms':b,'change_ms':b-a,'saved_percent':100*(1-b/a) if a else None,'pairs':[{'change_ms':bv[m]-av[m],'saved_percent':100*(1-bv[m]/av[m]) if av[m] else None} for av,bv in zip(values['A'],values['B'])]}
 primary=call=='update' and n==5000 and case in ['chart.bubble','chart.b.scatter']
 regression=all(b['total']-a['total']>max(.1,.05*a['total']) for a,b in zip(values['A'],values['B']))
 row={'case':case,'n':n,'call':call,'primary':primary,'metrics':metrics,'process_values':values,'repeatable_total_regression':regression}
 summary.append(row)
 t=metrics['total'];u=metrics['update']
 print(f'{case:18} {n:4} {call:6} update {u["baseline_ms"]:.4f}->{u["candidate_ms"]:.4f}; total {t["baseline_ms"]:.4f}->{t["candidate_ms"]:.4f} ({t["saved_percent"]:+.2f}% saved)')
primary=[r for r in summary if r['primary']]
assert len(summary)==15 and len(primary)==2
assert all(len(r['process_values'][v])==2 for r in summary for v in ['A','B'])
passed=all(all(p['saved_percent']>=5 for p in r['metrics']['update']['pairs']) for r in primary) and not any(r['repeatable_total_regression'] for r in summary)
(root/'summary.json').write_text(json.dumps({'protocol_passed':passed,'cells':summary},indent=2)+'\n')
print('Protocol passed:',passed)
