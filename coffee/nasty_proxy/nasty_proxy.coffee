# Lets require/import the HTTP module
http = require 'http'
url = require 'url'
querystring= require 'querystring'
http_request = require 'request'

_ = require 'underscore'

PORT=8080


#SKIP_RESPONSE_HEADERS = ["content-encoding"]
SKIP_RESPONSE_HEADERS = ["transfer-encoding", "content-encoding"]

SKIP_REQUEST_HEADERS = ["host", "if-modified-since", "if-none-match"]

should_skip_header = (name, coll)-> (name.toLowerCase() in coll)


# Helpers to copy headers from one request to another
copy_response_headers = (req_from, req_to)->
  return unless req_from.headers

  for k,v of req_from.headers
    if should_skip_header(k, SKIP_RESPONSE_HEADERS)
      console.log "    - Skipping header: '#{k}' : '#{v}'"
      continue

    req_to.setHeader k, v
    console.log "    + Copying header '#{k}' : '#{v}'"

copy_request_headers = (src_headers)->
  h = {}

  for k,v of src_headers
    if should_skip_header(k, SKIP_REQUEST_HEADERS)
      console.log "    - Skipping REQ header: '#{k}' : '#{v}'"
      continue

    h[k] = v
    console.log "    + Copying REQ header '#{k}' : '#{v}'"


  h
  #_.pick( src_headers, (v,k,o)-> k not in ["host"])

# handler to proxy a request to a remote target
proxy_req = (proxied_req, callback)->
  return callback() unless proxied_req.url

  req_str =  "#{proxied_req.method} #{proxied_req.url}"

  new_req =
    # make sure we allow bad certs so GitHub works
    rejectUnauthorized: false
    url: proxied_req.url
    gzip: true
    headers: copy_request_headers(proxied_req.headers)

  if proxied_req.auth
    new_req.headers['Authorization'] = proxied_req.auth

  console.log "--> Request: #{req_str} #{JSON.stringify(proxied_req, null, "    ")}"
  console.log "    Headers: #{JSON.stringify(new_req, null, "    ")}"

  req = http_request new_req, (error, response, body)->

    if error
      console.log "   Error!: #{error}"
      return callback( error, null, null)

    console.log "<-- Response #{response.statusCode} #{req_str} #{body.length} bytes"
    callback( error, response, body )

  req.on 'data', (data)->
    console.log "Got data:", data


# The main webapp handler
handleRequest = (request, response)->
  query = url.parse( request.url, true ).query
  console.log "-------> Incoming request: #{request.url}"

  query_url = query.url
  query_method = query.method ? "GET"

  unless query_url
    console.log "   404..."
    response.setHeader 'Server', 'got_yout_bitch_ass_chumped v0.9'
    response.end("Not found", 404)
    return

  proxied_req =
    url: query.url
    method: query.method ? "GET"
    params: JSON.parse( query.params ? "{}" )
    auth: query.auth
    headers: request.headers

  # store the credentials passed
  stored_credentials = JSON.parse( query.store ? "{}")
  console.log "====== STORING: #{JSON.stringify(stored_credentials)} ====="
  console.log request.auth

  proxy_req proxied_req, (err, proxied_resp, body)->
    if err
      return response.end("Request errror", 502)

    copy_response_headers( proxied_resp, response )
    #response.setHeader("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept")
    response.setHeader("Access-Control-Allow-Credentials", "true")
    response.setHeader("Access-Control-Allow-Origin", "*")
    response.end( body )

# Create a server
server = http.createServer(handleRequest)

# Lets start our server
server.listen PORT, ->
    # Callback triggered when server is successfully listening. Hurray!
    console.log("Server listening on: http:# localhost:%s", PORT);
