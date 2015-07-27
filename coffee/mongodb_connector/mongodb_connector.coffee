$ = require 'jquery'
_ = require 'underscore'

tableauHelpers = require '../connector_base/tableau_helpers.coffee'
wdc_base = require '../connector_base/starschema_wdc_base.coffee'
json_flattener = require './json_flattener.coffee'


load_json = (url, success_callback)->
  $.ajax
    url: url
    datatype: "json"
    success: (data, textStatus, request)->
      success_callback(data)
    error: (xhr, ajaxOptions, thrownError)->
      console.error("Error during search request", thrownError)
      tableau.abortWithError "Error while trying to load '#{url}'. #{thrownError}"

load_jsonp = (url, success_callback)->
  $.ajax
    url: url
    #async: false
    jsonpCallback: JSONP_CALLBACK_NAME
    contentType: "application/json",
    dataType: 'jsonp',
    success: (data, textStatus, request)->
      success_callback(data)
    error: (xhr, ajaxOptions, thrownError)->
      console.error("Error during search request", thrownError)
      tableau.abortWithError "Error while trying to load '#{url}'. #{thrownError}"

JSONP_CALLBACK_NAME = "mongodb_wdc_jsonp_callback"

wdc_base.make_tableau_connector
  name: "MongoDB connector"

  steps:
    start:
      template: require './start.jade'
    run:
      template: require './run.jade'
    run_mongo:
      template: require './run.jade'


  transitions:
    "start > run": (data)->
      _.extend data, wdc_base.fetch_inputs("#state-start")

    "start > run_mongo": (data)->
      _.extend data, wdc_base.fetch_inputs("#state-start")
      url = "http://#{data.mongodb_host}:#{data.mongodb_port}/#{data.mongodb_db}/#{data.mongodb_collection}"

      # Add the jsonP stuff
      url = "#{url}/?jsonp=#{JSONP_CALLBACK_NAME}"

      # Add some default page size
      url = "#{url}&limit=#{data.page_size}"


      if data.mongodb_params && data.mongodb_params != ""
        url = "#{url}&#{data.mongodb_params}"

      data.url = url

    "enter run": (data)->
      wdc_base.set_connection_data( data )
      tableau.submit()

    "enter run_mongo": (data)->
      wdc_base.set_connection_data( data )
      tableau.submit()

  rows: (connection_data, lastRecordToken)->
    offset_str = if lastRecordToken == "" then 0 else lastRecordToken
    offseted_url = "#{connection_data.url}&skip=#{offset_str}"
    console.log "offseted_url:", offseted_url
    load_jsonp offseted_url, (data)->

      {offset: offset, rows: rows, total_rows: total_rows} = data

      console.log {offset: offset, rows: rows, total_rows: total_rows}

      # when we reached the last page, it is signaled by returning
      # 0 rows
      has_more = (total_rows != 0)
      # the next page is the one after the current
      next_offset = offset + total_rows

      # Remap each row
      tableau_data = for row in rows
        json_flattener.remap(row, null).rows

      # Call back tableau
      tableau.dataCallback(_.flatten(tableau_data), next_offset.toString(), has_more)


  columns: (connection_data)->

    load_jsonp connection_data.url, (data)->
      tableau.abortWithError("No rows available in data") if _.isEmpty(data)

      # get the first row
      first_row = _.first( json_flattener.remap(_.first(data.rows)).rows )

      # Guess the data types of the columns
      datatypes = _.mapObject first_row, (v,k,o)->
       tableauHelpers.guessDataType(v)

      # Call back tableau
      tableau.headersCallback( _.keys(datatypes), _.values(datatypes))

