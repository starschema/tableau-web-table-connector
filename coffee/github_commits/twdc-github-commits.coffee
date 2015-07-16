_ = require 'underscore'
$ = require 'jquery'

connector_base = require '../connector_base/connector_base.coffee'

# Is the passed string a valid github identifier (has only valid characters)
is_valid_github_string = (str)-> str.test /[^a-zA-Z0-9_-]/

# get the commits url for a repo
github_commits_url = (user,repo)-> "https://api.github.com/repos/#{user}/#{repo}/commits"


connector_base.init_connector
  template: require('./source.jade')

  fields: [
    {type: 'string', key: 'username', selector: "#username"}
    {type: 'string', key: 'reponame', selector: "#reponame"}
  ]

  validator: (data)->
    return false unless data.username
    return false unless data.reponame
    return false unless is_valid_github_string(data.username)

    true

  columns: (connection_data)->
    return {
      names: ["author", "committer", "authored_at", "committed_at"]
      types: ["string", "string", "date", "date"]
    }

  submit_btn_selector: "#submit-button"


  rows: (connection_data, lastRecordToken)->

    connectionUrl = github_commits_url(connection_data.username, connection_data.reponame)
    tableau.log "Connecting to #{connectionUrl}"

    xhr = $.ajax
      url: connectionUrl,
      dataType: 'json',
      success: (data)->
        tableau.log "Got response"

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

        tableau.dataCallback( out, out.length.toString(), false)

      error: (xhr, ajaxOptions, thrownError)->
        # Add something to the log and return an empty set if there
        # was problem with the connection
        tableau.log "Connection error: #{xhr.responseText}\n#{thrownError}"
        tableau.abortWithError "Cannot connect to the specified GitHub repository."


