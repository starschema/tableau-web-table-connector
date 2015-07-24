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
      #console.log data, textStatus
      #tableau_data = for row in data
        #json_flattener.remap("row", row).rows

      #console.log _.flatten(tableau_data)
      #success_callback(

    error: (xhr, ajaxOptions, thrownError)->
      console.error("Error during search request", thrownError)
      tableau.abortWithError "Error while trying to load the tweets. #{thrownError}"

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
      url = "http://#{data.mongodb_host}:#{data.mongodb_port}/#{data.mongodb_collection}/#{data.mongodb_collection}"

      if data.mongodb_params && data.mongodb_params
        url = "#{url}/?#{data.mongodb_params}"

      data.url = url

    "enter run": (data)->
      wdc_base.set_connection_data( data )
      tableau.submit()

    "enter run_mongo": (data)->
      console.log data.url, data
      wdc_base.set_connection_data( data )
      tableau.submit()

  rows: (connection_data, lastRecordToken)->
    #tableau.dataCallback([], "", false)
    load_json connection_data.url, (data)->
      #console.log data, textStatus
      tableau_data = for row in data
        json_flattener.remap("row", row).rows

      tableau.dataCallback(_.flatten(tableau_data), "", false)
      #success_callback(


  columns: (connection_data)->

    load_json connection_data.url, (data)->
      tableau.abortWithError("No rows available in data") if _.isEmpty(data)
      #console.log data, textStatus
      #tableau_data = for row in data
      first_row = _.first( json_flattener.remap("row", _.first(data)).rows )

      datatypes = _.mapObject first_row, (v,k,o)->
       tableauHelpers.guessDataType(v)
      console.log _.keys(first_row), datatypes

      tableau.headersCallback( _.keys(datatypes), _.values(datatypes))
      #console.log _.flatten(tableau_data)
      #success_callback(

