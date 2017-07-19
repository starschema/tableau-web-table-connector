$ = require 'jquery'
_ = require 'underscore'

tableauHelpers = require '../connector_base/tableau_helpers.coffee'
wdc_base = require '../connector_base/starschema_wdc_base.coffee'
json_flattener = require './json_flattener.coffee'


load_json = (url, success_callback)->
  console.log("Getting URL", url)
  $.ajax
    url: url
    contentType: "application/json",
    success: (data, textStatus, request)->
      flat = json_flattener.remap(data)
      success_callback(flat)

    error: (xhr, ajaxOptions, thrownError)->
      console.error("Got error", thrownError)
      tableau.abortWithError "Error while trying to load '#{url}'. #{thrownError}"

JSONP_CALLBACK_NAME = "jsondb_wdc_jsonp_callback"

wdc_base.make_tableau_connector
  name: "Raw JSON connector"

  steps:
    start:
      template: require './start.jade'
    run_json:
      template: require './run.jade'


  transitions:
    "start > run_json": (data)->
      _.extend data, wdc_base.fetch_inputs("#state-start")

    "enter run_json": (data)->
      wdc_base.set_connection_data( data )
      tableau.submit()

  rows: (data, table, doneCallback)->
    load_json data.url, (rows)->
        table.appendRows(rows.rows)
        doneCallback()


  columns: (connection_data, schemaCallback)->

    load_json connection_data.url, (data)->
      tableau.abortWithError("No rows available in data") if _.isEmpty(data)

      first_row = _.first(data.rows)
      dataTypes = _.map first_row, (v,k,o)->
        { id: k, dataType: tableauHelpers.guessDataType(v)}

      tableInfo = {
        id : "json"
        alias: "JSON DATA"
        columns : dataTypes
      }

      # Call back tableau
      schemaCallback([tableInfo])

