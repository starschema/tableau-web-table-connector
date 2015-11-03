$ = require 'jquery'
_ = require 'underscore'
csv = require 'csv'


tableauHelpers = require '../connector_base/tableau_helpers.coffee'
wdc_base = require '../connector_base/starschema_wdc_base.coffee' 


load_csv = (url, params, success_callback)->
  $.ajax
    url: url
    # TODO: Setting this gives us some errors on some servers.
    #contentType: "text/html;charset=#{params.charset}"

    success: (res)->
      opts = _.defaults params,
        quote: '"'
        delimiter: ','
        columns: true
        auto_parse: true

      csv.parse res, opts, (err,data)-> success_callback(data)

    error: (xhr, ajaxOptions, thrownError)->
      tableau.abortWithError "Error while trying to load '#{url}'. #{thrownError}" 


wdc_base.make_tableau_connector
  name: "Simple CSV connector"

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

    load_csv connection_data.url, connection_data, (data)-> 

      # Call back tableau
      tableau.dataCallback data, "", false 


  columns: (connection_data)->

    load_csv connection_data.url, connection_data, (data)-> 
      tableau.abortWithError("No rows available in data") if _.isEmpty(data)

      # get the first row
      first_row = _.first data

      # Guess the data types of the columns
      datatypes = _.mapObject first_row, (v,k,o)->
       tableauHelpers.guessDataType(v)

      # Call back tableau
      tableau.headersCallback( _.keys(datatypes), _.values(datatypes))
 
