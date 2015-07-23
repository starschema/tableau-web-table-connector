$ = require 'jquery'
_ = require 'underscore'

state_machine = require '../connector_base/state_machine'



# Build the HTML from the states templates
build_html = (description, start_state="start")->
  states = for name, desc of description.steps
    style = []
    style.push("display:none;") unless name == start_state
    ["<div id='state-#{name}' style='#{style.join(' ')}'>", desc.template(), "</div>"].join("")

  states.join("")


build_state_machine = (description)->
  state_ids = _.mapObject( description.steps, (v,k,o)-> "#state-#{k}")
  #for k,v of description.steps
    #state_ids[k] = "#state-#{k}"
  transitionHandlers = description.transitions

  handlers = _.extend {}, transitionHandlers,
    "*": (data,from,to)->
      $steps(from).fadeOut(100)
      $steps(to).removeClass('hide').fadeIn(100)

  sm = state_machine.wizzard( "start", state_ids, transitionHandlers)
  sm



# HTML Helpers
# ------------

# Gets the value of an HTML input, and works on checkboxes too
$.fn.realVal = ()->
  $obj = $(this)
  val = $obj.val()
  type = $obj.attr('type')
  return val unless (type && type == 'checkbox')
  $obj.prop('checked') ? val : ($obj.attr('data-unchecked') ? '')


# Generates a reducer function to consturct an object from the *dataField* data
# attribute of an HTML input or select element and the value of that element.
dataKeyValueReducer = (dataField)->
  (memo,e)->
    $e = $(e)
    memo[$e.data(dataField)] = $e.realVal()
    memo

fetchInputs = (wrap_selector)->
    inputs = $("#{wrap_selector} [data-tableau-key]")
    console.log "GOT INPUTS:", inputs
    # Collect the input values into an object
    formData = _.reduce inputs, dataKeyValueReducer('tableau-key'), {}


# Add the transition event handlers
add_event_handlers = (description)->
  $('body').on 'click', '*[data-state-to]', (e)->
    e.preventDefault()
    transitions = $(@).data('state-to').split(/ +/)

# Tableau Connector related
# -------------------------

get_connection_data = -> JSON.parse( tableau.connectionData )
set_connection_data = (cd)-> tableau.connectionData = JSON.stringify( cd )


build_tableau_connector = (description)->
  connector = tableau.makeConnector()

  connector.getColumnHeaders = ->
    cols = description.columns(get_connection_data())
    tableau.headersCallback( cols.names, cols.types )

  connector.getTableData = (lastRecordToken)->
    description.rows( get_connection_data(), lastRecordToken)

  tableau.registerConnector(connector)


#TWITTER_GET_OAUTH_TOKEN_URL = "https://api.twitter.com/oauth2/token"

## Get the OAuth bearer token from twitter
#fetch_bearer_token = (auth_token, callback)->
  #req = $.ajax
    #type: "POST"
    #url: TWITTER_GET_OAUTH_TOKEN_URL
    #data: "grant_type=client_credentials"
    #datatype: "json"
    ## Add the authorization header
    #beforeSend: (xhr)->
      #console.log('Authorization', auth_token)
      #xhr.setRequestHeader('Authorization', auth_token)
    #success: (data, textStatus, request)->
      #console.log "Got reply from twitter:", data, textStatus,request
      #callback(null, data)

    #error: (xhr, ajaxOptions, thrownError)->
      #console.error("Error during auth request", thrownError)
      #callback(thrownError, null)
      #

#sanitize_col_name = (col_name)->col_name.replace(/\./g, '__')

extract_column = (data, col_name)->
  col_name_parts = col_name.split('.')
  obj = data
  o = {}
  o[col_name] = null
  for col_name_part in col_name_parts
    if /^[0-9]+$/.test(col_name_part)
      col_name_part = parseInt( col_name_part )

    return o if obj[col_name_part] == null
    obj = obj[col_name_part]

  o[col_name] = obj
  o



make_columns = (data)->
  cols = {names: [], types: [], extractors:[]}

  for col in data
    c = col.split(':')
    col_name = c[0]
    #sanitized_col_name = sanitize_col_name(col_name)
    cols.names.push col_name
    cols.types.push c[1]



  cols


EXTRACT_COLS = make_columns( [
  #'metadata.iso_language_code:text'
  'created_at:date'
  'text:text'
  'user.name:text'
  'user.screen_name:text'
  'user.location:text'
  'user.followers_count:text'

  'geo.coordinates.0:text'
  'geo.coordinates.1:text'
  #'place:text'
  #'coordinates.:text'

  'retweet_count:integer'
  'favorite_count:integer'

  'lang:text'
])


# Generate the list of column names based on the filtering flags
get_twitter_columns = (filter_flags)->
  o = [
    'lang:text'
    'created_at:date'
    'text:text'
    'user.name:text'
    'retweet_count:int'
    'favorite_count:int'
  ]

  if filter_flags.include_geolocation
    o.push(
      'geo.coordinates.0:text'
      'geo.coordinates.1:text'
    )

  if filter_flags.include_userdata
    o.push(
      'user.screen_name:text'
      'user.location:text'
      'user.followers_count:int'
    )

  if filter_flags.expand_hashtags
    o.push "hashtag:text"

  if filter_flags.expand_mentions
    o.push "mention_screen_name:text"
    o.push "mention_username:text"

  # Generate the column data
  make_columns(o)


# generate new rows from data based on the filter/expand flags
expand_twitter_rows = (row_data, column_names, filter_flags)->

  # Extract data from a single row
  extract_row = (row)->
    _.extend( {}, _.map(column_names, (c)-> extract_column(row,c) )...)


  unless filter_flags.expand_hashtags or filter_flags.expand_mentions
    return extract_row(row_data)

  out_rows = []

  # the base for the row
  row_out = extract_row(row_data)

  # Add each hashtag
  if filter_flags.expand_hashtags
    if _.isEmpty( row_data.entities.hashtags )
      out_rows.push _.clone( row_out )
    else
      for hashtag in row_data.entities.hashtags
        out_rows.push _.extend( {}, row_out, {hashtag: hashtag.text} )

  # Add each hashtag
  if filter_flags.expand_mentions
    if _.isEmpty( row_data.entities.user_mentions )
      out_rows.push _.clone( row_out )
    else
      for mention in row_data.entities.user_mentions
        out_rows.push _.extend( {}, row_out, {mention_screen_name: mention.screen_name, mention_username: mention.name} )

  out_rows


# The twitter connector itself
connector_data =
  name: "Twitter Connector"

  steps:

    # The start where we ask for credentials and what to search for
    start:
      template: require './start.jade'
    auth:
      template: require './auth.jade'

    run:
      template: require './run.jade'

  transitions:

    "start > run": (data, from, to)->
      _.extend data, fetchInputs("#state-start")
      #inputs = 
      #data.q = inputs.q

    #"auth > run": (data)->
      #_.extend data, fetchInputs("#state-auth")

    "enter run": (data)->
      set_connection_data( data )
      tableau.submit()

  rows: (connection_data, lastRecordToken)->
    tableau.log "Starting to fetch a batch -- lastRecordToken:'#{lastRecordToken}'"
    tableau.abortWithError("No search terms provided") unless connection_data.q

    ## The pagination data
    #if lastRecordToken != ""
      #tableau.abortWithError("Error while parsing pagination token:#{JSON.stringify lastRecordToken}")
      #return

    pagination = {
      url: "/search?q=#{encodeURIComponent(connection_data.q)}"
      pages: parseInt(connection_data.page_count)
    }

    if lastRecordToken and lastRecordToken != ""
      pagination = JSON.parse(lastRecordToken)

    $.ajax
      url: pagination.url
      datatype: "json"
      success: (data, textStatus, request)->

        extract_column_desc = get_twitter_columns(connection_data)

        tableau_data = []
        for row in data.statuses
          tableau_data = tableau_data.concat expand_twitter_rows( row, extract_column_desc.names, connection_data)


        next_page = {
          url: "/search#{data.search_metadata.next_results}"
          pages: pagination.pages - 1
        }

        have_more = (next_page.pages > 0)

        #tableau.abortWithError("stringify: #{JSON.stringify(next_page)} have_more:#{ have_more}")
        tableau.dataCallback(tableau_data, JSON.stringify(next_page), have_more )

      error: (xhr, ajaxOptions, thrownError)->
        console.error("Error during search request", thrownError)
        tableau.abortWithError "Error while trying to load the tweets. #{thrownError}"

  columns: (connection_data)->
    get_twitter_columns(connection_data)

$ ->
  $('#twdc-ui').html( build_html( connector_data ))
  sm = build_state_machine( connector_data )
  build_tableau_connector(connector_data)
  #add_event_handlers( connector_data )
