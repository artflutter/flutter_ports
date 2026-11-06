#!/usr/bin/env python3
# Usage: run_ios.py <app dir> <out file> <timeout s>
# Installs the lab, starts it and copies its result file from the phone until MATRIX_DONE.
import subprocess,sys,time,json,tempfile,os
app,out,to=sys.argv[1],sys.argv[2],int(sys.argv[3])
dev='00008150-001870922140401C'; bundle='dev.artflutter.chartBenchmarkLab'
def dc(*a,check=True): return subprocess.run(['xcrun','devicectl',*a],capture_output=True,text=True,check=check)
lock=dc('device','info','lockState','--device',dev).stdout
if 'passcodeRequired: true' in lock: raise SystemExit('iPhone locked')
dc('device','install','app','--device',dev,app)
dc('device','process','launch','--device',dev,'--terminate-existing',bundle)
t0=time.time(); done=False
tmp=out+'.part'
while time.time()-t0<to:
    time.sleep(15)
    r=dc('device','copy','from','--device',dev,'--domain-type','appDataContainer','--domain-identifier',bundle,'--source','tmp/matrix_lines.txt','--destination',tmp,check=False)
    if r.returncode==0 and os.path.exists(tmp):
        text=open(tmp,errors='replace').read()
        open(out,'w').write(text)
        rows=sum(1 for l in text.splitlines() if l.startswith(('MATRIX {','EVERYDAY {')))
        print(int(time.time()-t0),'s rows',rows,flush=True)
        if 'MATRIX_DONE' in text: done=True; break
print('done' if done else 'timeout', int(time.time()-t0),flush=True)
print(dc('device','info','lockState','--device',dev).stdout.strip()[-60:])
