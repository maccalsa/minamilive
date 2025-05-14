from http.server import HTTPServer, SimpleHTTPRequestHandler
from urllib.error import HTTPError
import urllib.request
from urllib.parse import urlparse

class ProxyHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        # Parse the URL
        parsed_path = urlparse(self.path)
        
        # If the path starts with /api, proxy to backend
        if parsed_path.path.startswith('/api'):
            # Forward the request to the backend
            backend_url = f'http://localhost:8000{self.path}'
            print(f"Proxying request to: {backend_url}")
            
            # Create request with headers
            req = urllib.request.Request(backend_url)
            
            # Forward all headers except host
            for header in self.headers:
                if header.lower() != 'host':
                    req.add_header(header, self.headers[header])
                    
            try:
                # Get response from backend
                with urllib.request.urlopen(req) as response:
                    # Get response data
                    response_data = response.read()
                    print(f"Response status: {response.status}")
                    print(f"Response headers: {response.getheaders()}")
                    print(f"Response body: {response_data.decode()}")
                    
                    # Send response status
                    self.send_response(response.status)
                    
                    # Copy response headers
                    for header in response.getheaders():
                        if header[0].lower() not in ['transfer-encoding', 'content-encoding', 'content-length']:
                            # Modify Set-Cookie header to work with our proxy
                            if header[0].lower() == 'set-cookie':
                                cookie = header[1]
                                # Remove SameSite=none if present
                                cookie = cookie.replace('; SameSite=none', '')
                                self.send_header(header[0], cookie)
                            else:
                                self.send_header(header[0], header[1])
                    
                    # Set content length
                    self.send_header('Content-Length', str(len(response_data)))
                    self.end_headers()
                    
                    # Send response body
                    self.wfile.write(response_data)
                return
            except HTTPError as e:
                # Handle HTTP errors (401, 403, etc.)
                error_body = e.read()
                print(f"HTTP error from backend ({e.code}): {error_body.decode()}")
                
                self.send_response(e.code)
                for header in e.headers.items():
                    if header[0].lower() not in ['transfer-encoding', 'content-encoding', 'content-length']:
                        self.send_header(header[0], header[1])
                self.send_header('Content-Length', str(len(error_body)))
                self.end_headers()
                self.wfile.write(error_body)
            except Exception as e:
                print(f"Error proxying request: {e}")
                self.send_error(500, f"Error proxying request: {str(e)}")
            return
        
        # For all other requests, serve static files
        return SimpleHTTPRequestHandler.do_GET(self)

def log_message(self, format, *args):
    # Custom logging to see all requests
    print(f"[{self.address_string()}] {format%args}")

def run(server_class=HTTPServer, handler_class=ProxyHandler, port=5500):
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    print(f"Starting proxy server on port {port}")
    httpd.serve_forever()

if __name__ == '__main__':
    run() 