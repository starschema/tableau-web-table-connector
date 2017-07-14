$ = require 'jquery'
_ = require 'underscore'

tableauHelpers = require '../connector_base/tableau_helpers.coffee'
wdc_base = require '../connector_base/starschema_wdc_base.coffee'
json_flattener = require './json_flattener.coffee'


load_jsonp = (url, success_callback)->
  $.ajax
    url: url
    #async: false
    # jsonpCallback: JSONP_CALLBACK_NAME
    contentType: "application/json",
    # dataType: 'jsonp',
    success: (data, textStatus, request)->
      success_callback(json_flattener.remap(data))

    error: (xhr, ajaxOptions, thrownError)->
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
    # offset_str = if lastRecordToken == "" then 0 else lastRecordToken
    # offseted_url = "#{connection_data.url}&skip=#{offset_str}"
    #


    load_jsonp data.url, (rows)->


        # for (var i = 0, len = feat.length; i < len; i++) {
        #     tableData.push({
        #         "id": feat[i].id,
        #         "mag": feat[i].properties.mag,
        #         "title": feat[i].properties.title,
        #         "lon": feat[i].geometry.coordinates[0],
        #         "lat": feat[i].geometry.coordinates[1]
        #     });
        # }

        console.log("ROWS are:", rows.rows)
        table.appendRows(rows.rows)
        doneCallback()
      # Remap each row
      # tableau_data = for row in rows
      #   json_flattener.remap(row, null).rows

      # Call back tableau
      # doneCallback(_.flatten(tableau_data), "", false)


  columns: (connection_data, schemaCallback)->

    load_jsonp connection_data.url, (data)->
      tableau.abortWithError("No rows available in data") if _.isEmpty(data)

      first_row = _.first(data.rows)
      dataTypes = _.map first_row, (v,k,o)->
        { id: k, dataType: tableauHelpers.guessDataType(v)}

      console.log("DATATYPES:", dataTypes)

      tableInfo = {
        id : "json"
        alias: "JSON DATA"
        columns : dataTypes
      }

      # Call back tableau
      schemaCallback([tableInfo])

