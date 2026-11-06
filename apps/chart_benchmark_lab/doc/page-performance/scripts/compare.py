#!/usr/bin/env python3
# Usage: compare.py <results dir> <target>... Prints old against new for each scenario, the mean of the runs of each side.
import json,glob,os,sys
root=sys.argv[1]; targets=sys.argv[2:] or ['chrome','safari','firefox','macos','android']
def load(side,target):
    runs=[]
    for f in sorted(glob.glob(f'{root}/{side}.*/{target}.txt')):
        rows={}
        for line in open(f,errors='replace'):
            i=line.find('PAGE {')
            if i>=0:
                try:
                    d=json.loads(line[i+5:]); rows[d['scenario']]=d
                except Exception: pass
        if rows: runs.append(rows)
    return runs
names=['startup','idle','scroll.empty','scroll.table','run.readout','filter.chip','sort.table','settings.expand','toggle.feature','slider.drag','library.switch','dialog.open','hover.controls','run.pause','resize.light','resize.heavy']
keys=[('frames','frames'),('uiP50','uiP50'),('uiP90','uiP90'),('uiP99','uiP99'),('uiMax','uiMax'),('rP50','rasterP50'),('rP90','rasterP90'),('rP99','rasterP99'),('rMax','rasterMax'),('over','overBudget'),('late','lateGaps')]
def mean(runs,s,k):
    v=[r[s][k] for r in runs if s in r and k in r[s]]
    return sum(v)/len(v) if v else None
for t in targets:
    a=load('base',t); b=load('new',t)
    print(f'\n## {t}: old runs {len(a)}, new runs {len(b)}')
    print('scenario'.ljust(16)+''.join(k[0].rjust(16) for k in keys))
    for s in names:
        if not any(s in r for r in a+b): continue
        if s=='startup':
            print('startup'.ljust(16)+f"first frame ms: {mean(a,s,'firstFrameMs')} -> {mean(b,s,'firstFrameMs')}"); continue
        cells=[]
        for _,k in keys:
            x=mean(a,s,k); y=mean(b,s,k)
            f=lambda v: '-' if v is None else (f'{v:.0f}' if k in('frames','overBudget','lateGaps') else f'{v:.1f}')
            cells.append(f'{f(x)}>{f(y)}'.rjust(16))
        print(s.ljust(16)+''.join(cells))
