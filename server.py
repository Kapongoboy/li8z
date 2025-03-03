import http.server
import socketserver

class CustomHandler(http.server.SimpleHTTPRequestHandler):
    def guess_type(self, path):
        if path.endswith('.js'):
            return 'application/javascript; charset=utf-8'
        if path.endswith('.wasm'):
            return 'application/wasm'
        if path.endswith('.html'):
            return 'text/html; charset=utf-8'
        if path.endswith('.ico'):
            return 'image/x-icon'
        return super().guess_type(path)

PORT = 8080
Handler = CustomHandler
with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print(f"Serving at http://localhost:{PORT}/web/")
    httpd.serve_forever()
