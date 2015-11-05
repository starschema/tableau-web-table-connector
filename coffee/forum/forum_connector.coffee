$ = require 'jquery'
_ = require 'underscore'


tableauHelpers = require '../connector_base/tableau_helpers.coffee'
wdc_base = require '../connector_base/starschema_wdc_base.coffee'

# TODO: implement your HTTP logic
load_url = (url, success_callback)->
  $.ajax
    url: url
    dataType: "text"
    success: (res)->
      res = res.substring(res.indexOf("\n") + 1)

      success_callback( JSON.parse(res) )

    error: (xhr, ajaxOptions, thrownError)->
      tableau.abortWithError "Error while trying to load '#{url}'. #{thrownError}"


wdc_base.make_tableau_connector
  name: "Simple XXX connector"

  steps:
    start:
      template: require './start.jade'
    run:
      template: require './run.jade'


  transitions:
    "start > run": (data)->
      _.extend data, wdc_base.fetch_inputs("#state-start")

      data.url = "http://localhost:1337/community.tableau.com/api/core/v3/contents?filter=tag(#{data.tags})&filter=type(document,discussion)"

    "enter run": (data)->
      wdc_base.set_connection_data( data )
      tableau.submit()

  rows: (connection_data, lastRecordToken)->

    load_url connection_data.url, (data)->

      # Call back tableau
      tableau.dataCallback data.list, "", false


  columns: (connection_data)->

    # Call back tableau
    tableau.headersCallback ["subject", "viewCount", "published"], ["string", "int", "date"]
