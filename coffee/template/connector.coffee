$ = require 'jquery'
_ = require 'underscore'


tableauHelpers = require '../connector_base/tableau_helpers.coffee'
wdc_base = require '../connector_base/starschema_wdc_base.coffee'

# TODO: implement your HTTP logic
load_url = (url, success_callback)->
  $.ajax
    url: url
    success: (res)->
      success_callback(data)

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


    "enter run": (data)->
      wdc_base.set_connection_data( data )
      tableau.submit()

  rows: (connection_data, lastRecordToken)->

    load_url connection_data.url, (data)->

      # Call back tableau
      tableau.dataCallback data, "", false


  columns: (connection_data)->

    load_url connection_data.url, (data)->
      tableau.abortWithError("No rows available in data") if _.isEmpty(data)

      # get the first row
      first_row = _.first data

      # Guess the data types of the columns
      datatypes = _.mapObject first_row, (v,k,o)->
       tableauHelpers.guessDataType(v)

      # Call back tableau
      tableau.headersCallback( _.keys(datatypes), _.values(datatypes))
