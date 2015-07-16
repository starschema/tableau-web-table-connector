$ = require 'jquery'
_ = require 'underscore'

init_connector = (data)->
  $(document).ready ->
    build_connector(data)


gather_fields = (fields)->
  o = {}
  for field in fields
    o[field.key] = $(field.selector).val()
  JSON.stringify(o)

get_connection_data = -> JSON.parse( tableau.connectionData )




build_connector = (data)->

  connector = tableau.makeConnector()

  connector.getColumnHeaders = ->
    #connectionData = tableau.connectionData
    cols = data.columns(get_connection_data())
    #cols = _.result( data, "columns", {names: [], types: []} )
    tableau.headersCallback( cols.names, cols.types )

  connector.getTableData = (lastRecordToken)->
    rows = data.rows( get_connection_data(), lastRecordToken)
    # do the data callback
    #tableau.dataCallback(rows, rows.length.toString(), false)


  $(document).ready ()->
    # render the tamplate
    $(".ui").html( data.template() )

    # set up the submitter
    $(data.submit_btn_selector).click ->
      tableau.connectionData = gather_fields( data.fields )
      tableau.submit()
      false

  tableau.registerConnector(connector)


module.exports =
  init_connector: init_connector
