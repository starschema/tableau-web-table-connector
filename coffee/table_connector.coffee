_ = require 'underscore'
$ = require "jquery"
global.jQuery = $
require 'bootstrap'

stateMachine = require './lib/state_machine'
tableSource  = require './lib/table_source'

# PROVIDERS
# ---------

providers =
  googleDocs : require './providers/google_docs/google_docs'
  csv        : require './providers/csv/csv'


# CoffeeScript version of Google Spreadsheet Driver for Tableau Data Web Connector

# UNDERSCORE EXTENSIONS
# ---------------------
_.mixin
  # Allows fn to transform both the keys and values of the object.
  #
  # Like other underscore functions, fn takes a (value,key) as input and should
  # return an object whos keys will be added to the output object.
  #
  # Returns an object containing all the keys from each iteration of fn,
  # overwriting existing keys as the iteration progresses.
  remapObject: (obj,fn)->
    # _.extend takes any number of arguments and the reducer
    # function gets called with more then 2 arguments, so it
    # whould merge them
    _.reduce( _.map(obj,fn), ((m,o)->_.extend(m,o)), {})

  # Shortcut to create a brand new object from a key-value pair
  makePair: (key,value)-> o={};o[key]=value;o


# TEMPLATING
# ----------
templates =
  tablePreview : require './table_preview.jade'
  sourceSelect : require './source_select.jade'


# Renders a template available at *templateSel* into an HTML element
# specified by *targetSel* using *context* for lookup.
renderInto = (targetSel, template, context)->
  $(targetSel).html(template(context))


# HELPERS
# -------
# Returns an object with the field *name* set to the value of the input
# matching the jquery selector *selector*
grabFormField = (selector,name)-> _.makePair(name,$(selector).val())


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

# TABLEAU CALLBACKS
# -----------------

# Initializes the tableau connection
init = ->
  unless tableau
    alert 'init- tableau NOT defined!'
    return
  tableau.scriptVersion = '1.0'
  tableau.initCallback()


# Forward the shutdown to tablaus shutdown
shutdown = -> tableau.shutdownCallback()


mainTabs = stateMachine.wizzard "start", {
    start:"#docs-start",
    loading:"#loading",
    preview:"#data-preview"
    import:"#importing",
  },

  "start > loading": (data)->
    #$('#select-source-wrapper').fadeOut(100)
    # Find out which source we are using
    dataSource = $('#select-source').val()

    # Find all inputs marked as needed for this datasource
    inputs = $("[data-tableau-provider=\"#{dataSource}\"] [data-tableau-key]")

    # Collect the input values into an object
    formData = _.reduce inputs, dataKeyValueReducer('tableau-key'), {}

    # Append to the existing state data so we can use it on import
    _.extend data, formData, _source: dataSource

    loader = providers[dataSource].loader()
    loader formData, (table)->
      renderInto '#data-preview-table', templates.tablePreview,
        cols:tableSource.getColumns(table)
        firstRow: table[1]
      mainTabs.to('preview')


  "preview > import": (data)->
    data._columns = _.map $('[data-tableau-row]'), (e)->
      _.reduce $('[data-tableau-key]', e), dataKeyValueReducer('tableau-key'), {}

    tableau.connectionData = JSON.stringify( data )
    tableau.log("Connection data: #{tableau.connectionData}")
    tableau.connectionName = 'Google Spreadsheet Data'
    tableau.submit()

  "preview > start": ->

  "enter start": -> $('#select-source-wrapper').fadeIn(100)
  "leave start": -> $('#select-source-wrapper').fadeOut(100)


# Shortcut for the connectiondata
getConnectionData = -> JSON.parse(tableau.connectionData)

# Filter the *cols* list to include only imported columns
getImportedColumns = (cols)-> _.filter(cols, (c)->c.import )

# Helper to load the table from the tableau connection data.
loadFromConnectionData = (data,callback)->
  loader = providers[data._source].loader()
  loader data, (table)->
    callback(table)

# Tableau callback to get the headers from the spreadsheet
getColumnHeaders = ->
  data = getConnectionData()
  loadFromConnectionData data, (table)->
    columns = _.filter( data._columns, (c)-> c.import ) # tableSource.getColumns(table)
    tableau.headersCallback( _.pluck(columns, 'name'), _.pluck(columns, 'type'))

getTableData = (lastRecordNumber) ->
  # Since we are downloading the spreadsheet as-is
  # there are no more pages
  if lastRecordNumber
    tableau.dataCallback [], lastRecordNumber
    return

  data = getConnectionData()
  loadFromConnectionData data, (table)->
    columnNameMap = _.reduce getImportedColumns(data._columns),
      ((memo,c)-> memo[c.key] = c.name; memo)
      {}

    # We need to remap the keys
    remapper = (v,k)-> _.makePair(columnNameMap[k], v)

    newTable = _.map table, (row)-> _.remapObject( row, remapper )
    console.log "NEW TABLE:", newTable

    tableau.dataCallback( table, -1 )


# The form fields we are interested in
FORM_FIELDS = {key:"#key", tab:"#tab", _source: "#select-source" }

$(document).ready ->

  $("[data-tableau-provider]").each ->
    $t = $(this)
    $t.html( providers[$t.data('tableau-provider')].template() )

  # Add all known providers to the provider dropdown
  renderInto '#select-source', templates.sourceSelect, providers:providers

  lastSource = _.keys(providers)[0]
  $('#select-source').change ->
    source = $(this).val()
    return if source == lastSource

    $("[data-tableau-provider=\"#{lastSource}\"]").fadeOut 100, ->
      $("[data-tableau-provider=\"#{source}\"]").removeClass('hide').fadeIn 100, ->
        lastSource = source


# Export the tableau-specific event handlers from our coffeescript
# module in case we arent compiled with --bare and the top level
# definitions in this module are scoped inside an anonymous function.
_.extend window,
  init: init
  shutdown: shutdown
  getTableData: getTableData
  getColumnHeaders: getColumnHeaders

