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

# Create a cached getter
getTemplate = _.memoize( (selector)-> _.template($(selector).html()))

# Helper to render a template
render = (selector, context)-> getTemplate(selector)(context)

# Renders a template available at *templateSel* into an HTML element
# specified by *targetSel* using *context* for lookup.
renderInto = (targetSel, templateSel, context)->
  $(targetSel).html(render(templateSel,context))


# HELPERS
# -------
# Returns an object with the field *name* set to the value of the input
# matching the jquery selector *selector*
grabFormField = (selector,name)-> _.makePair(name,$(selector).val())


providers =
  googleDocs:
    name:   "Google Documents Spreadsheet"
    loader: googleDocsLoader

  csv:
    name:   "CSV Data"
    loader: csvLoader

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


mainTabs = wizzard "start", {
    start:"#docs-start",
    loading:"#loading",
    preview:"#data-preview"
    import:"#importing",
  },

  "start > loading": (data)->
    $('#select-source-wrapper').fadeOut(100)
    # Find out which source we are using
    dataSource = $('#select-source').val()
    console.log "selected data source:", dataSource

    # Find all inputs marked as needed for this datasource
    inputs = $("[data-tableau-provider=\"#{dataSource}\"] [data-tableau-key]")

    # Helper to collect a list of inputs and map them to keys
    collectInputValues = (memo,e)->
      $e = $(e)
      memo[$e.data('tableau-key')] = $e.val()
      memo

    # Collect the input values into an object
    formData = _.reduce inputs, collectInputValues, {}

    # Append to the existing state data so we can use it on import
    _.extend data, formData, _source: dataSource

    loader = providers[dataSource].loader()
    loader formData, (table)->
      renderInto("#data-preview-table", "#header-table-tpl", cols:getColumns(table))
      mainTabs.to('preview')


  "preview > import": (data)->
    tableau.connectionData = JSON.stringify( data )
    tableau.log("Connection data: #{tableau.connectionData}")
    tableau.connectionName = 'Google Spreadsheet Data'
    tableau.submit()

  "preview > start": ->
    $('#select-source-wrapper').fadeIn(100)


# Helper to load the table from the tableau connection data.
loadFromConnectionData = (callback)->
  data = JSON.parse(tableau.connectionData)
  loader = providers[data._source].loader()
  #loader = googleDocsLoader()
  loader data, (table)->
    callback(table)


# Tableau callback to get the headers from the spreadsheet
getColumnHeaders = ->
  loadFromConnectionData (table)->
    columns = getColumns(table)
    tableau.headersCallback( _.pluck(columns, 'name'), _.pluck(columns, 'type'))

getTableData = (lastRecordNumber) ->
  # Since we are downloading the spreadsheet as-is
  # there are no more pages
  if lastRecordNumber
    tableau.dataCallback [], lastRecordNumber
    return

  loadFromConnectionData (table)->tableau.dataCallback( table, -1 )


# The form fields we are interested in
FORM_FIELDS = {key:"#key", tab:"#tab", _source: "#select-source" }

$(document).ready ->
  # Add all known providers to the provider dropdown
  renderInto "#select-source", "#source-select-tpl", providers:providers
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

