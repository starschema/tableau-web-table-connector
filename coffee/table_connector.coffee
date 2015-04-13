# CoffeeScript version of Google Spreadsheet Driver for Tableau Data Web Connector
#
_ = require 'underscore'
$ = require "jquery"
global.jQuery = $
require 'bootstrap'

stateMachine = require './lib/state_machine'
tableSource  = require './lib/table_source'

# Loads the providers list
providers = require '../providers/providers.coffee'


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
    _.extend( {}, _.map(obj,fn)...)

  # Shortcut to create a brand new object from a key-value pair
  makePair: (key,value)-> o={};o[key]=value;o


# TEMPLATING
# ----------
templates =
  tablePreview : require './table_preview.jade'
  sourceSelect : require './source_select.jade'
  providerForms: require './provider_forms.jade'


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


previewErrorHandler = (err,args...)->
  $('#errorText').text(err.toString())
  mainTabs.to('error', err: err, args: args)

importErrorHandler = previewErrorHandler


# Find out which source we are using
getDataSource = -> dataSource = $('#select-source').val()

# Find all inputs marked as needed for this datasource
fetchInputs = (dataSourceName)->
    inputs = $("[data-tableau-provider=\"#{dataSourceName}\"] [data-tableau-key]")
    # Collect the input values into an object
    formData = _.reduce inputs, dataKeyValueReducer('tableau-key'), {}

# Submit a source for loading with tableau
tableauSubmitWithData = (data)->
  tableau.connectionData = JSON.stringify( data )
  tableau.log("Connection data: #{tableau.connectionData}")
  tableau.connectionName = 'Starschema Web Data Connector'
  tableau.submit()



mainTabs = stateMachine.wizzard "start", {
    start:"#docs-start",
    loading:"#loading",
    preview:"#data-preview"
    import:"#importing",

    error: '#error'
  },

  "start > loading": (data)->
    dataSource = getDataSource()
    formData = fetchInputs(dataSource)
      #
    # Append to the existing state data so we can use it on import
    _.extend data, formData, _source: dataSource

    loader = providers[dataSource].loader(previewErrorHandler)
    loader formData, (table)->
      renderInto '#data-preview-table', templates.tablePreview,
        cols:tableSource.getColumns(table)
        firstRow: table[1]
      mainTabs.to('preview')


  "preview > import": (data)->
    data._columns = _.map $('[data-tableau-row]'), (e)->
      _.reduce $('[data-tableau-key]', e), dataKeyValueReducer('tableau-key'), {}

    tableauSubmitWithData(data)

  "start > import": (data)->
    dataSource = getDataSource()
    formData = fetchInputs(dataSource)

    # Append to the existing state data so we can use it on import
    _.extend data, formData, _source: dataSource

    tableauSubmitWithData(data)


  # Show and hide the source selector
  "enter start": -> $('#select-source-wrapper').fadeIn(100)
  "leave start": -> $('#select-source-wrapper').fadeOut(100)


# Shortcut for the connectiondata
getConnectionData = -> JSON.parse(tableau.connectionData)

# Filter the *cols* list to include only imported columns
getImportedColumns = (cols)-> _.filter(cols, (c)->c.import )

# Helper to load the table from the tableau connection data.
loadFromConnectionData = (data, errorHandler, callback)->
  loader = providers[data._source].loader(errorHandler)
  loader data, (table)->
    callback(table)

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

# Get the column information either from the import settings or use
# the tables columns if no imports are specified
getColumnInformation = (columns, table)->
  if columns then getImportedColumns(columns) else tableSource.getColumns(table)

# Tableau callback to get the headers from the spreadsheet
getColumnHeaders = ->
  data = getConnectionData()
  loadFromConnectionData data, importErrorHandler, (table)->
    # Get the column information
    columns = getColumnInformation( data._columns, table )
    tableau.headersCallback( _.pluck(columns, 'name'), _.pluck(columns, 'type'))


getTableData = (lastRecordNumber) ->
  # Since we are downloading the spreadsheet as-is
  # there are no more pages
  if lastRecordNumber
    tableau.dataCallback [], lastRecordNumber
    return

  data = getConnectionData()

  loadFromConnectionData data, importErrorHandler, (table)->
    # Reducer for making a key->col name map
    remappingReducer = ((memo,c)-> memo[c.key] = c.name; memo)

    columns = getColumnInformation( data._columns, table )
    columnNameMap = _.reduce columns, remappingReducer, {}

    # We need to remap the keys using the old name -> new name map
    remapper = (v,k)-> _.makePair(columnNameMap[k], v)

    # Remap all rows this way
    newTable = _.map table, (row)-> _.remapObject( row, remapper )

    # Pass the data to tableau
    tableau.dataCallback( newTable, -1 )


$(document).ready ->

  # Render the providers forms
  renderInto "#provider-forms", templates.providerForms, providers:providers
  # Add all known providers to the provider dropdown
  renderInto '#select-source', templates.sourceSelect, providers:providers

  # Dirty selector for provider selection via the dropdown
  lastSource = _.keys(providers)[0]
  $('#select-source').change ->
    source = $(this).val()
    return if source == lastSource

    $("[data-tableau-provider=\"#{lastSource}\"]").fadeOut 100, ->
      $("[data-tableau-provider=\"#{source}\"]").removeClass('hide').fadeIn 100, ->
        lastSource = source

  $("#provider-forms .form-select-source:first").removeClass('hide')


# Export the tableau-specific event handlers from our coffeescript
# module in case we arent compiled with --bare and the top level
# definitions in this module are scoped inside an anonymous function.
_.extend window,
  init: init
  shutdown: shutdown
  getTableData: getTableData
  getColumnHeaders: getColumnHeaders

