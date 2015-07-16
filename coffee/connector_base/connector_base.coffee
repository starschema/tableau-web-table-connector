$ = require 'jquery'

init_connector = (delegate)->
  data = fields: [], template: (()->)

  # Helper to declare fields
  it.needs = (type, key)->
    data.fields.push( type: type, key: key )

  it.template = (fn)->
    data.template = fn

  delegate(it)

build_connector = ->

  connector = tableau.makeConnector()

  connector.getColumnHeaders = ->
    # Tell Tableau about the fields and their types

  connector.getTableData = (lastRecordToken)->
     #/ Call back to Tableau with the table data


  connector

  $(document).ready ()->
     #/ on document ready (jQuery)

  tableau.registerConnector(connector)
