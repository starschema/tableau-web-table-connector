# Github Tableau Web Data Connector

This is a very basic connector designed to showcase some basic aspects
of the Tableau Web Data Connector architecture.

## Purpose of the connector

Enable us to get a list of commits from a repository and then create
reports about the contributions, contributors and the dates the
contributions came.

We'll use the GitHub REST API to access these commits. The URL to access
these is:

```
https://api.github.com/repos/<user>/<repo>/commits
```

This returns us a JSON array of commits: [sample commit list](https://api.github.com/repos/tfoldi/fuse-tableaufs/commits).

There are two aspects of this API endpoint we need to take into
consideration:

- Non-authenticated requests are limited to 60 requests/hour, so we need
  to add **basic authentication**
- A single request only returns a limited number of commits, so we need
  **pagination**

So lets tackle those challanges one-by-one.


## Getting started with the connector

We'll be using the Starschema WDC Connector Base to write our connector
since it simplifies some basic tasks (like creating a simple UI).

The construction of the UI and basic states of the connector basically
mirror the structure of the MongoDB connector:

```coffee
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
```

The only real difference here is storing the username / password pair
inside the encrypted tableau.password field as a JSON object to
authenticate the requests in the callbacks and removing them from the
connection data object so they wont be stored unencrypted.

## Getting the metadata

Since github always returns the same data, we can keep the metadata
static:

```coffee
GITHUB_COLUMNS =
  names: ['author_name', 'committer_name', 'author', 'authored_at', 'committer', 'committed_at']
  types: ['text', 'text','text', 'date', 'text', 'date']
```

And do the header callback using this static object:

```coffee
  columns: (connection_data)->
    tableau.headersCallback( GITHUB_COLUMNS.names, GITHUB_COLUMNS.types )
```


## Getting the commit data

Lets go over the ```rows()``` function that returns the actual commit
data:

```coffee
  rows: ( connection_data, lastRecordToken)->
    {user: auth_user, password: auth_password} = JSON.parse(tableau.password)
```

First we deserialize the username and password from the encrypted
storage so we can do authentication if necessary.

```coffee
    # the URL of the first page
    connectionUrl = github_commits_url(connection_data.username, connection_data.reponame)
```

Then figure out the github URL for the commits from the connection
data.

```coffee
    # if we are in a pagination loop, use the last record token to load the next page
    if lastRecordToken.length > 0
      connectionUrl = lastRecordToken
```

If we are not on the first page (the lastRecordToken isnt empty) then
the url of the next page is already stored in the ```lastRecordToken```
so we set the connection url to that.


Next we need to build up the parameters for our AJAX call:

```coffee
    xhr_params =
      url: connectionUrl,
      dataType: 'json',
      success: (data, textStatus, request)->
        # [... Success handler / will be detailed later ...]
      error: (xhr, ajaxOptions, thrownError)->
        # Add something to the log and return an empty set if there
        # was problem with the connection
        err =  "Connection error: #{xhr.responseText} -- #{thrownError}"
        tableau.log err
        tableau.abortWithError "Cannot connect to the specified GitHub repository. -- #{err}"

```

These parameters are always necessary, and they represent a very basic AJAX
call to githubs api. Thankfully the GitHub API uses CORS headers so we
wont have any trouble when it comes to cross-site script access.


After creating the parameter object, we may need to add the
authentication header to it if we set up the connector for
authentication:

```coffee
    # Add the auth handler if necessary
    if connection_data.do_auth
      xhr_params = apply_auth(xhr_params, auth_user, auth_password)
```

The apply_auth helper simply adds an authorization header to our
request:


```coffee
make_base_auth = (user, password)-> "Basic #{btoa("#{user}:#{password}")}"

apply_auth = (params, username, password)->
  _.extend {}, params,
      beforeSend: (xhr)->
        xhr.setRequestHeader('Authorization', make_base_auth(username, password))

```


After the AJAX parameter setup is complete, we just need to call it:

```coffee
    $.ajax xhr_params
```


Now we have created and dispatched the request, so its time to look at
what happens when we have received a reply (aka. the succes handler):


```coffee
        link_headers = parse_link_header( request.getResponseHeader('Link') )
```

For pagination, the response returned by GitHub contains a header named ```Link```
which contains the pagination information that we need to parse with our
little helper:

```coffee
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
```

Next we'll check if we actually received the correct response. We do
this by checking if the response is an actual array:

```coffee
        # Stop if no commits present
        unless _.isArray(data)
          tableau.abortWithError "GitHub returned an invalid response."
```

Now we know that the data we received can be iterated, so lets just do
that and collect the data we need from each commmit:

```coffee
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
```

This simply turns our array of complicated commit objects into a simple
flat object that we'll return to Tableau.

All thats left for us is to check if we need to load more pages and call
the ```tableau.dataCallback()``` function:

```coffee
        has_more =  if link_headers.next then true else false
        tableau.dataCallback( out, link_headers.next, has_more)
```
