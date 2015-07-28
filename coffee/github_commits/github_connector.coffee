$ = require 'jquery'
_ = require 'underscore'

tableauHelpers = require '../connector_base/tableau_helpers.coffee'
wdc_base = require '../connector_base/starschema_wdc_base.coffee'


# get the commits url for a repo
github_commits_url = (user,repo)-> "https://api.github.com/repos/#{user}/#{repo}/commits"

GITHUB_COLUMNS =
  names: ['author_name', 'committer_name', 'author', 'authored_at', 'committer', 'committed_at']
  types: ['text', 'text','text', 'date', 'text', 'date']

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


make_base_auth = (user, password)-> "Basic #{btoa("#{user}:#{password}")}"

apply_auth = (params, username, password)->
  _.extend {}, params,
      beforeSend: (xhr)->
        xhr.setRequestHeader('Authorization', make_base_auth(username, password))




wdc_base.make_tableau_connector
  steps:
    start:
      template: require './start.jade'
    run:
      template: require './run.jade'

  transitions:
    "start > run" : (data)->
      _.extend data, wdc_base.fetch_inputs("#state-start")

    "enter run": (data)->
      # save the password
      tableau.password = JSON.stringify
        user: data.auth_username
        password: data.auth_password

      # Remove the sensitive data from the connection_data
      delete data.auth_username
      delete data.auth_password

      wdc_base.set_connection_data(data)

      tableau.submit()

  rows: ( connection_data, lastRecordToken)->
    {user: auth_user, password: auth_password} = JSON.parse(tableau.password)

    # the URL of the first page
    connectionUrl = github_commits_url(connection_data.username, connection_data.reponame)

    # if we are in a pagination loop, use the last record token to load the next page
    if lastRecordToken.length > 0
      connectionUrl = lastRecordToken

    tableau.log "Connecting to #{connectionUrl}"

    xhr_params =
      url: connectionUrl,
      dataType: 'json',
      success: (data, textStatus, request)->
        link_headers = parse_link_header( request.getResponseHeader('Link') )
        tableau.log "Got response - links: #{JSON.stringify(link_headers)}"

        # Stop if no commits present
        unless _.isArray(data)
          tableau.abortWithError "GitHub returned an invalid response."

        out = for commit_data in data
          # shorten names
          {committer: cc, author: ca} = commit_data.commit
          # return the data
          {
            author_name: ca.name
            committer_name: cc.name

            author: ca.email
            committer: cc.email

            authored_at: ca.date
            committed_at: cc.date
          }

        has_more =  if link_headers.next then true else false
        tableau.dataCallback( out, link_headers.next, has_more)

      error: (xhr, ajaxOptions, thrownError)->
        # Add something to the log and return an empty set if there
        # was problem with the connection
        err =  "Connection error: #{xhr.responseText} -- #{thrownError}"
        tableau.log err
        tableau.abortWithError "Cannot connect to the specified GitHub repository. -- #{err}"

    # Add the auth handler if necessary
    if connection_data.do_auth
      xhr_params = apply_auth(xhr_params, auth_user, auth_password)


    $.ajax xhr_params


  columns: (connection_data)->
    tableau.headersCallback( GITHUB_COLUMNS.names, GITHUB_COLUMNS.types )

