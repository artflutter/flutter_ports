#!/usr/bin/env python3
# Usage: run_android.py <apk> <out file> <timeout s>
# Waits for a cool phone, starts the lab, keeps the logcat lines and a thermal log with one line for each 5 s.
import subprocess,sys,time,re,threading
apk,out,to=sys.argv[1],sys.argv[2],int(sys.argv[3])
dev='4B071JEKB17363'; pkg='dev.artflutter.chart_benchmark_lab'
def adb(*a,check=True): return subprocess.run(['adb','-s',dev,*a],capture_output=True,text=True,check=check).stdout
def state():
    s=adb('shell','cat /sys/devices/system/cpu/cpu8/cpufreq/scaling_max_freq /sys/devices/system/cpu/cpu8/cpufreq/scaling_cur_freq /sys/devices/system/cpu/cpu8/cpufreq/cpuinfo_max_freq; dumpsys battery | grep -E "temperature|level|AC powered|USB powered"; dumpsys thermalservice | grep -m1 "Thermal Status"')
    n=s.split('\n')
    return dict(maxf=int(n[0]),cur=int(n[1]),top=int(n[2]),temp=int(re.search(r'temperature: (\d+)',s).group(1))/10,level=int(re.search(r'level: (\d+)',s).group(1)),status=int(re.search(r'Thermal Status: (\d+)',s).group(1)))
saved={k:adb('shell','settings','get','system',k).strip() for k in ['peak_refresh_rate','min_refresh_rate']}
stay=adb('shell','settings','get','global','stay_on_while_plugged_in').strip()
print('saved',saved,'stay',stay,flush=True)
try:
    adb('shell','settings','put','system','peak_refresh_rate','120')
    adb('shell','settings','put','system','min_refresh_rate','120')
    adb('shell','svc','power','stayon','usb')
    # The gate before the start: a full clock on the big core, no thermal status, and a battery at most 35 C.
    t0=time.time()
    while True:
        st=state()
        if st['maxf']>=st['top'] and st['status']==0 and st['temp']<=35: break
        print('waiting',st,flush=True)
        if time.time()-t0>1800: raise SystemExit('phone stays hot')
        time.sleep(20)
    print('start',st,flush=True)
    adb('install','-r',apk)
    adb('shell','am','force-stop',pkg)
    adb('logcat','-c')
    adb('shell','am','start','-n',pkg+'/.MainActivity')
    time.sleep(2)
    pid=adb('shell','pidof',pkg).strip()
    log=open(out,'w')
    proc=subprocess.Popen(['adb','-s',dev,'logcat','--pid='+pid,'-v','raw','-s','flutter:I'],stdout=log,stderr=subprocess.DEVNULL)
    therm=open(out+'.thermal','w'); stop=[False]
    def poll():
        while not stop[0]:
            try:
                s=state(); s['t']=int(time.time()*1000); therm.write(repr(s)+'\n'); therm.flush()
            except Exception as e: therm.write('error %r\n'%(e,)); therm.flush()
            time.sleep(5)
    th=threading.Thread(target=poll,daemon=True); th.start()
    t0=time.time(); done=False; last=0
    while time.time()-t0<to:
        time.sleep(5)
        text=open(out,errors='replace').read()
        rows=sum(1 for l in text.splitlines() if l.startswith(('MATRIX {','EVERYDAY {')))
        if rows!=last: print(int(time.time()-t0),'s rows',rows,flush=True); last=rows
        if 'MATRIX_DONE' in text: done=True; break
        if adb('shell','pidof',pkg,check=False).strip()!=pid: print('process ended',flush=True); break
    stop[0]=True; proc.terminate()
    adb('shell','am','force-stop',pkg,check=False)
    print('done' if done else 'timeout',int(time.time()-t0),state(),flush=True)
finally:
    for k,v in saved.items():
        if v=='null': adb('shell','settings','delete','system',k,check=False)
        else: adb('shell','settings','put','system',k,v,check=False)
    adb('shell','settings','put','global','stay_on_while_plugged_in',stay,check=False)
    print('restored',flush=True)
