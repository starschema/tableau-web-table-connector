$ = require 'jquery'
_ = require 'underscore'

state_machine = require '../connector_base/state_machine'


make_tableau_connector = (connector_data)->
  $ ->
    $('#twdc-ui').html( build_html( connector_data ))
    sm = build_state_machine( connector_data )
    build_tableau_connector(connector_data)



# Build the HTML from the states templates
build_html = (description, start_state="start")->
  states = for name, desc of description.steps
    style = []
    style.push("display:none;") unless name == start_state
    ["<div id='state-#{name}' style='#{style.join(' ')}'>", desc.template(), "</div>"].join("")

  states.join("")


build_state_machine = (description)->
  state_ids = _.mapObject( description.steps, (v,k,o)-> "#state-#{k}")
  #for k,v of description.steps
    #state_ids[k] = "#state-#{k}"
  transitionHandlers = description.transitions

  handlers = _.extend {}, transitionHandlers,
    "*": (data,from,to)->
      $steps(from).fadeOut(100)
      $steps(to).removeClass('hide').fadeIn(100)

  sm = state_machine.wizzard( "start", state_ids, transitionHandlers)
  sm



# HTML Helpers
# ------------

# Gets the value of an HTML input, and works on checkboxes too
$.fn.realVal = ()->
  $obj = $(this)
  val = $obj.val()
  type = $obj.attr('type')
  return val unless (type && type == 'checkbox')
  $obj.prop('checked') ? val : ($obj.attr('data-unchecked') ? '')


# Generates a reducer function to consturct an object from the *dataField* data
# attribute of an HTML input or select element and the value of that element.
dataKeyValueReducer = (dataField)->
  (memo,e)->
    $e = $(e)
    memo[$e.data(dataField)] = $e.realVal()
    memo

fetchInputs = (wrap_selector)->
    inputs = $("#{wrap_selector} [data-tableau-key]")
    console.log "GOT INPUTS:", inputs
    # Collect the input values into an object
    formData = _.reduce inputs, dataKeyValueReducer('tableau-key'), {}


# Add the transition event handlers
add_event_handlers = (description)->
  $('body').on 'click', '*[data-state-to]', (e)->
    e.preventDefault()
    transitions = $(@).data('state-to').split(/ +/)

# Tableau Connector related
# -------------------------

get_connection_data = -> JSON.parse( tableau.connectionData )
set_connection_data = (cd)-> tableau.connectionData = JSON.stringify( cd )


build_tableau_connector = (description)->
  connector = tableau.makeConnector()

  #connector.getColumnHeaders = ->
  connector.getSchema = (schemaCallback)->
    description.columns(get_connection_data(), schemaCallback)

  connector.getData = (lastRecordToken)->
    description.rows( get_connection_data(), lastRecordToken)

  tableau.registerConnector(connector)


extract_column = (data, col_name)->
  col_name_parts = col_name.split('.')
  obj = data
  o = {}
  o[col_name] = null
  for col_name_part in col_name_parts
    if /^[0-9]+$/.test(col_name_part)
      col_name_part = parseInt( col_name_part )

    return o if obj[col_name_part] == null
    obj = obj[col_name_part]

  o[col_name] = obj
  o



make_columns = (data)->
  cols = {names: [], types: [], extractors:[]}

  for col in data
    c = col.split(':')
    col_name = c[0]
    #sanitized_col_name = sanitize_col_name(col_name)
    cols.names.push col_name
    cols.types.push c[1]



  cols

_.extend module.exports,
  make_tableau_connector: make_tableau_connector
  fetch_inputs: fetchInputs
  set_connection_data: set_connection_data
  get_connection_data: get_connection_data
  make_columns: make_columns
  extract_column: extract_column
