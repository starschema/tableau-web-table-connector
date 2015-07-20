$ = require 'jquery'
_ = require 'underscore'
_ = require './underscore_starschema'

init_connector = (data)->
  $(document).ready ->
    build_connector(data)


gather_fields = (fields)->
  o = {}
  for field in fields
    $field = $(field.selector)
    val = $field.val()

    # handle checkboxed properly
    if $field.attr('type') == 'checkbox'
      val = $field.is(':checked')

    # update the value in the connection data
    o[field.key] = val

  o


get_connection_data = -> JSON.parse( tableau.connectionData )
set_connection_data = (cd)-> tableau.connectionData = JSON.stringify( cd )

apply_auth_fn = (connection_data, auth_fn)->
  return unless auth_fn

  [new_cd, auth_data] = auth_fn( connection_data )

  # update the connection data
  set_connection_data( new_cd )

  # update the tableau auth data
  {username: tableau.username, password: tableau.password } = auth_data


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
      # Clean the username and password (why-oh-why? the simulator seems to give
      # a type error if this isnt set after using auth once)
      [tableau.username, tableau.password] = ["",""]

      set_connection_data(  gather_fields( data.fields ) )
      apply_auth_fn( get_connection_data(), data.authorize )
      # do the authorize callbacks
      tableau.submit()
      false

  tableau.registerConnector(connector)


module.exports =
  init_connector: init_connector
