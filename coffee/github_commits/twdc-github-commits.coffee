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


connector_base.init_connector
  template: require('./source.jade')

  fields: [
    { key: 'username', selector: "#username"}
    { key: 'reponame', selector: "#reponame"}
  ]

  columns: (connection_data)->
    return {
      names: ["author", "committer", "authored_at", "committed_at"]
      types: ["string", "string", "date", "date"]
    }

  submit_btn_selector: "#submit-button"


  rows: (connection_data, lastRecordToken)->
    console.log lastRecordToken

    connectionUrl = github_commits_url(connection_data.username, connection_data.reponame)

    # if we are in a pagination loop, use the last record token to load the next page
    if lastRecordToken.length > 0
      connectionUrl = lastRecordToken

    tableau.log "Connecting to #{connectionUrl}"

    xhr = $.ajax
      url: connectionUrl,
      dataType: 'json',
      success: (data, textStatus, request)->
        tableau.log "Got response"
        link_headers = parse_link_header( request.getResponseHeader('Link') )
        console.log link_headers

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
        tableau.log "Connection error: #{xhr.responseText}\n#{thrownError}"
        tableau.abortWithError "Cannot connect to the specified GitHub repository."


