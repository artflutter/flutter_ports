#!/usr/bin/env python3
# Serves a folder with the COOP and COEP headers, and writes each POST /line body to a file.
import functools, http.server, sys
folder, port, out = sys.argv[1], int(sys.argv[2]), sys.argv[3]
class H(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cross-Origin-Opener-Policy','same-origin')
        self.send_header('Cross-Origin-Embedder-Policy','require-corp')
        self.send_header('Cross-Origin-Resource-Policy','cross-origin')
        self.send_header('Cache-Control','no-store')
        super().end_headers()
    def do_POST(self):
        n=int(self.headers.get('Content-Length',0)); b=self.rfile.read(n).decode('utf8','replace')
        with open(out,'a') as f: f.write(b+'\n')
        self.send_response(204); self.end_headers()
    def log_message(self,*a): pass
H.extensions_map={**H.extensions_map,'.wasm':'application/wasm','.mjs':'text/javascript'}
http.server.ThreadingHTTPServer(('127.0.0.1',port),functools.partial(H,directory=folder)).serve_forever()
