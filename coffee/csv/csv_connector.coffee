$ = require 'jquery'
_ = require 'underscore'
csv = require 'csv'


tableauHelpers = require '../connector_base/tableau_helpers.coffee'
wdc_base = require '../connector_base/starschema_wdc_base.coffee'


load_csv = (url, params, success_callback)->
  console.log params, "000"

  opts =  _.extend {
        quote: '"'
        delimiter: ','
        columns: true
        auto_parse: true
  }, params

  # Handle tab as delimiter
  if opts.delimiter == 'TAB'
    opts.delimiter = "\t"

  $.ajax
    url: url
    # TODO: Setting this gives us some errors on some servers.
    #contentType: "text/html;charset=#{params.charset}"

    success: (res)->
      csv.parse res, opts, (err,data)-> success_callback(data)

    error: (xhr, ajaxOptions, thrownError)->
      tableau.abortWithError "Error while trying to load '#{url}'. #{thrownError}"

aliasToId = (alias)-> alias.replace(/[^A-Za-z0-9]+/g, "_")

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

  rows: (connection_data, table, doneCallback) ->
    console.log("Connection data", connection_data)

    load_csv connection_data.url, connection_data, (data)->
      # Convert the columns aliases to ids
      table.appendRows(data.map( (row)->
        o = {}
        Object.keys(row).forEach (k)->
          o[aliasToId(k)] = row[k]
        return o
      ))

      ## Call back tableau
      doneCallback()


  columns: (connection_data, schemaCallback) ->

    load_csv connection_data.url, connection_data, (data)->
      tableau.abortWithError("No rows available in data") if _.isEmpty(data)

      # get the first row
      first_row = _.first data

      # Call back tableau
      schemaCallback [
        id: "CSV"
        # Guess the datatype for each column
        columns: Object.keys(first_row).map (key)->
          { alias: key, id: aliasToId(key) , dataType: tableauHelpers.guessDataType( first_row[key] ) }
      ]

