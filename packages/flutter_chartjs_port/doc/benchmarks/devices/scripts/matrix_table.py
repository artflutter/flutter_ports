#!/usr/bin/env python3
# Usage: matrix_table.py <file>... : FPS for each cell, with the UI and raster figures.
import json,re,sys
types=['line','bar','scatter','bubble','pie','doughnut','polarArea','radar']
for path in sys.argv[1:]:
    rows={}
    for line in open(path,errors='replace'):
        m=re.search(r'MATRIX (\{.*\})',line)
        if m:
            d=json.loads(m.group(1)); rows[(d['type'],d['count'],d['preset'])]=d
    print(path.split('/')[-1],len(rows),'cells')
    any_=next(iter(rows.values()))
    print(' viewport',any_.get('viewport'),'dpr',any_.get('dpr'),'hz',any_.get('refreshHz'))
    print(f"{'type':10}"+''.join(f"{n}{p[0]:<8}" for n in (1000,5000,20000) for p in ('plain','full')))
    for t in types:
        o=f'{t:10}'
        for n in (1000,5000,20000):
            for p in ('plain','full'):
                d=rows.get((t,n,p)); o+=f"{d['fps'] if d and 'fps' in d else -1:<9.0f}" if d else f"{'-':9}"
        print(o)
    print('slow cells (below 119): fps busyP90 rasterP90 uiP90 update draw')
    for k,d in rows.items():
        if d.get('fps',0)<119: print(' ',k,d.get('fps'),d.get('busyP90'),d.get('rasterP90'),d.get('uiP90'),d.get('updateMs'),d.get('drawMs'),'cal',d.get('calMs'),d.get('calAfterMs'))
    errs=[l.strip()[:150] for l in open(path,errors='replace') if 'ERROR' in l or 'RETRY' in l]
    print(' errors',len(errs),errs[:3])
