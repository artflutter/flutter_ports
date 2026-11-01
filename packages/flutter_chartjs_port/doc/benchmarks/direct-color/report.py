from pathlib import Path
import json,statistics as st,csv,os,gzip,sys
root=Path(__file__).resolve().parent
runs=[]
if '--recorded' in sys.argv:
 for entry in json.loads(gzip.decompress((root/(os.environ.get('RUN_DIR','runs')+'-measurements.json.gz')).read_bytes())):
  runs.append((entry['state'],entry['rows']))
else:
 for f in sorted((root/os.environ.get('RUN_DIR','runs')).glob('*.state.json')):
  state=json.loads(f.read_text())
  if state['complete']:
   rows=json.loads(f.with_name(f.name.replace('.state.json','.json')).read_text())
   runs.append((state,rows))
print('Complete runs:',[x[0]['name'] for x in runs])
checks={}
for state,rows in runs:
 for r in rows:
  if r.get('check')=='pixels': checks.setdefault(r['case'],set()).add((r['hash'],r['nonzero']))
print('Pixel checks:',checks)
assert all(len(v)==1 for v in checks.values()),'Pixel difference'
def key(r):return (r.get('kind'),r.get('case'),r.get('n'),r.get('call'))
def value(r):
 if r['kind']=='micro': return r['medianNs']
 return sum(float(r.get(p+'MedianMs',0)) for p in ('update','draw','end'))
by={}
for state,rows in runs:
 for r in rows:
  if r.get('kind') not in ('micro','chart'):continue
  by.setdefault(key(r),{'A':[],'B':[]})[state['name']].append(value(r))
report=[]
for k,ab in by.items():
 if not ab['A'] or not ab['B']:continue
 a,b=map(st.median,(ab['A'],ab['B']))
 row={'kind':k[0],'case':k[1],'n':k[2],'call':k[3],'A':a,'B':b,'reductionPct':100*(1-b/a),'speedup':a/b,'A_runs':ab['A'],'B_runs':ab['B']}
 pairs=[]
 for i in range(0,len(runs)-1,2):
  left,right=runs[i:i+2]
  assert {left[0]['name'],right[0]['name']}=={'A','B'}
  ar,br=(left,right) if left[0]['name']=='A' else (right,left)
  av=next(value(r) for r in ar[1] if key(r)==k)
  bv=next(value(r) for r in br[1] if key(r)==k)
  pairs.append(100*(1-bv/av))
 row['pairedReductionPct']=pairs
 report.append(row)
 print(f'{k}: {a:.4f} -> {b:.4f}; {row["reductionPct"]:.1f}% less; {row["speedup"]:.2f}x')
(root/(os.environ.get('RUN_DIR','runs')+'-summary.json')).write_text(json.dumps(report,indent=2))
if report:
 with (root/(os.environ.get('RUN_DIR','runs')+'-summary.csv')).open('w') as out:
  w=csv.DictWriter(out,fieldnames=report[0].keys());w.writeheader();w.writerows(report)
