#!/usr/bin/env python3
import json,re,sys
for path in sys.argv[1:]:
    rows=[]
    for line in open(path,errors='replace'):
        m=re.search(r'EVERYDAY (\{.*\})',line)
        if m: rows.append(json.loads(m.group(1)))
    print(path.split('/')[-1],len(rows),'rows; plot',rows[0].get('plot') if rows else '')
    for sc in ['mount','animate','hover','resize']:
        rs=[r for r in rows if r['scenario']==sc and r.get('pass',1)==1]
        if not rs: continue
        print(' ',sc)
        for r in rs:
            if 'error' in r: print('   ',r['type'],r['count'],'ERROR',r['error'][:80]); continue
            extra=f" first {r.get('firstDrawP50')}/{r.get('firstDrawP90')}" if sc=='mount' else ''
            print(f"    {r['type']:10}{r['count']:<6} fps {r.get('fps',0):<7.1f} raster {r.get('rasterP90',0):<7.1f} busy {r.get('busyP90',0):<7.1f} ui {r.get('uiP90',0):<7.1f} upd {r.get('updateMs',0):<7.2f} draw {r.get('drawMs',0):<6.2f}{extra} cal {r.get('calMs')}")
    for r in rows:
        if r['scenario'] not in ('mount','animate','hover','resize'):
            print(f"  {r['scenario']:16} n {r['count']:<6} fps {r.get('fps',0):<7.1f} raster {r.get('rasterP90',0):<7.1f} busy {r.get('busyP90',0):<7.1f} ui {r.get('uiP90',0):<7.1f} upd {r.get('updateMs',0):<7.2f} draw {r.get('drawMs',0):<6.2f} {r.get('error','')[:70]}")
