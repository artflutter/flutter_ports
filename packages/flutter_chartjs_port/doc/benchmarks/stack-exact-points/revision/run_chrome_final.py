from pathlib import Path
from http.server import BaseHTTPRequestHandler,HTTPServer
import threading,json,subprocess,signal,time
root=Path(__file__).resolve().parent;out=root/'chrome-final';out.mkdir(exist_ok=True)
received=[]
class Handler(BaseHTTPRequestHandler):
 def do_POST(self):
  received.append(json.loads(self.rfile.read(int(self.headers['Content-Length']))))
  self.send_response(200);self.send_header('Access-Control-Allow-Origin','*');self.end_headers();self.wfile.write(b'ok')
 def log_message(self,*args):pass
server=HTTPServer(('127.0.0.1',8899),Handler)
threading.Thread(target=server.serve_forever,daemon=True).start()
try:
 for v in ['A','C','C','A']:
  tag=f'{len(list(out.glob("*.json"))):02d}-{v}';received.clear()
  with (out/(tag+'.log')).open('w') as log:
   proc=subprocess.Popen(['flutter','run','-d','chrome','--release','--wasm','--web-port=8898','--web-browser-flag=--headless','-t','lib/main_stack_guardfirst.dart','--dart-define=VARIANT='+v],cwd=root/v/'app',stdout=log,stderr=subprocess.STDOUT)
   start=time.time()
   while not received and proc.poll() is None and time.time()-start<240:time.sleep(.5)
   proc.send_signal(signal.SIGINT)
   try:proc.wait(timeout=20)
   except subprocess.TimeoutExpired:proc.terminate();proc.wait(timeout=10)
  assert received,(out/(tag+'.log')).read_text()[-3000:]
  rows=received[0]
  (out/(tag+'.json')).write_text(json.dumps({'variant':v,'platform':'chrome-wasm','rows':rows},indent=2))
  assert isinstance(rows,list) and len(rows)==10 and all(r['build']=='release' for r in rows),rows
  print('Chrome wasm',tag,'10 release cells',flush=True)
  time.sleep(4)
finally:server.shutdown()
