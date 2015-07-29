$ = require 'jquery'
_ = require 'underscore'

wdc_base = require '../connector_base/starschema_wdc_base.coffee'

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
    o.push( 'geo.coordinates.0:text'
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
  wdc_base.make_columns(o)


# generate new rows from data based on the filter/expand flags
expand_twitter_rows = (row_data, column_names, filter_flags)->

  # Extract data from a single row
  extract_row = (row)->
    _.extend( {}, _.map(column_names, (c)-> wdc_base.extract_column(row,c) )...)


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
      _.extend data, wdc_base.fetch_inputs("#state-start")
      #inputs = 
      #data.q = inputs.q

    #"auth > run": (data)->
      #_.extend data, fetchInputs("#state-auth")

    "enter run": (data)->
      wdc_base.set_connection_data( data )
      tableau.submit()

  rows: (connection_data, lastRecordTokenBase64)->
    # De-base64 the last record token to get around a Tableau Desktop issue
    # with quotes in the lastRecordToken
    lastRecordToken = atob(lastRecordTokenBase64)

    tableau.log "Starting to fetch a batch -- lastRecordToken:'#{lastRecordToken}'"
    tableau.abortWithError("No search terms provided") unless connection_data.q

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

        # Re-encode the new lastRecordToken with base64 to get around
        # the Tableau Desktop lastRecordToken issue.
        reencodedLastRecordToken = btoa(JSON.stringify(next_page))

        tableau.dataCallback(tableau_data, reencodedLastRecordToken, have_more )

      error: (xhr, ajaxOptions, thrownError)->
        console.error("Error during search request", thrownError)
        tableau.abortWithError "Error while trying to load the tweets. #{thrownError}"

  columns: (connection_data)->
    cols = get_twitter_columns(connection_data)
    tableau.headersCallback( cols.names, cols.types )


wdc_base.make_tableau_connector( connector_data )
#$ ->
  #$('#twdc-ui').html( build_html( connector_data ))
  #sm = build_state_machine( connector_data )
  #build_tableau_connector(connector_data)
  ##add_event_handlers( connector_data )
