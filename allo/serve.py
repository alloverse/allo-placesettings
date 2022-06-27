from http.server import HTTPServer, BaseHTTPRequestHandler
import threading, os, json, asyncio, subprocess, json

APPS_ROOT = os.getenv('APPS_ROOT')

class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        destination = self.headers.get("x-alloverse-server")
        launchargs = "{}"
        app_name = self.path

        app_path = "." # by default, just launch current app
        if APPS_ROOT and app_name:
            # if serving many apps, pick the app based on root and given name
            app_path = APPS_ROOT+'/'+app_name

        print(f"Booting app {app_path or ''} into {destination}...")
        try:
            content_len = int(self.headers.get('Content-Length'))
            launchargs = self.rfile.read(content_len)
            sub_env = os.environ.copy()
            sub_env["ALLO_APP_BOOT_ARGS"] = launchargs
            if not destination:
                raise Exception("missing destination")
            subprocess.Popen(
                ["./allo/assist", "run", destination],
                cwd=app_path,
                env=sub_env
            )
            # todo: reap it when it exits
            self.send_response(200)
            self.end_headers()
            print("Process launched.")
            self.wfile.write(bytes(json.dumps({"status": "ok"}), "utf-8"))
        except Exception as e:
            error = f"Failed to boot app: {e}"
            print(error)
            self.send_response(502)
            self.end_headers()
            self.wfile.write(bytes(json.dumps({"status": "error", "error": error}), "utf-8"))

def start_server(handler, port=8000):
    '''Start a simple webserver serving path on port'''
    httpd = HTTPServer(('', port), handler)
    httpd.serve_forever()

def run_gateway_server(handler = Handler, port = 8000):
    # Start the server in a new thread
    daemon = threading.Thread(name='daemon_server', target=start_server, args=(handler, port))
    daemon.setDaemon(True) # Set as a daemon so it will be killed once the main thread is dead.
    daemon.start()
    return daemon

if __name__ == "__main__":
    print(f"Serving AlloApp(s) from {APPS_ROOT or 'current directory'}")
    run_gateway_server().join()
