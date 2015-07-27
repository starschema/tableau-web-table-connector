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
    async: false
    jsonpCallback: JSONP_CALLBACK_NAME
    contentType: "application/json",
    dataType: 'jsonp',
    success: (data, textStatus, request)->
      success_callback(data.rows)
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


      if data.mongodb_params && data.mongodb_params != ""
        url = "#{url}#{data.mongodb_params}"

      data.url = url

    "enter run": (data)->
      wdc_base.set_connection_data( data )
      tableau.submit()

    "enter run_mongo": (data)->
      wdc_base.set_connection_data( data )
      tableau.submit()

  rows: (connection_data, lastRecordToken)->
    load_jsonp connection_data.url, (data)->
      tableau_data = for row in data
        json_flattener.remap(row, null).rows

      tableau.dataCallback(_.flatten(tableau_data), "", false)


  columns: (connection_data)->

    load_jsonp connection_data.url, (data)->
      tableau.abortWithError("No rows available in data") if _.isEmpty(data)

      first_row = _.first( json_flattener.remap(_.first(data)).rows )

      datatypes = _.mapObject first_row, (v,k,o)->
       tableauHelpers.guessDataType(v)
      console.log _.keys(first_row), datatypes

      tableau.headersCallback( _.keys(datatypes), _.values(datatypes))

