# CoffeeScript version of Google Spreadsheet Driver for Tableau Data Web Connector
# Tamas Foldi, 

init = ->
  if !tableau
    alert 'init- tableau NOT defined!'
    return
  tableau.scriptVersion = '1.0'
  tableau.log 'init'
  tableau.initCallback()

shutdown = ->
  tableau.shutdownCallback()

getConnectionURL = (connectionData) ->
  "http://spreadsheets.google.com/feeds/list/#{connectionData['key']}/#{connectionData['tab']}/public/values?alt=json"

getColumnHeaders = ->
  tableau.log 'spreadsheets - getColumnHeaders connectionData=' + tableau.connectionData
  tableau.addWhiteListEntry 'http', 'spreadsheets.google.com'
  $.ajax
    url: getConnectionURL( JSON.parse tableau.connectionData )
    dataType: 'json'
    success: (res) ->
      entry = res.feed.entry[0]
      fieldNames = []
      fieldTypes = []
      for key of entry
        if entry.hasOwnProperty(key) and key[0..3] == 'gsx$'
          fieldVal = entry[key].$t
          if parseInt(fieldVal).toString() == fieldVal
            fieldType = 'int'
          else if parseFloat(fieldVal).toString() == fieldVal
            fieldType = 'float'
          else if isFinite(new Date(fieldVal).getTime())
            fieldType = 'date'
          else
            fieldType = 'string'
          fieldNames.push key[4..]
          fieldTypes.push fieldType
      tableau.headersCallback fieldNames, fieldTypes
      return
  return

getTableData = (lastRecordNumber) ->
  tableau.log 'spreadsheets - getColumnHeaders connectionData=' + tableau.connectionData
  if lastRecordNumber
    tableau.dataCallback [], lastRecordNumber
    return
  $.ajax(
    url: getConnectionURL( JSON.parse tableau.connectionData )
    dataType: 'json'
    success: (data) ->
      toRet = []
      
      for entry in data.feed.entry
        row = {}
        for key of entry
          if entry.hasOwnProperty(key) and key[0..3] == 'gsx$'
            fieldName = key[4..]
            fieldVal = entry[key].$t
            row[fieldName] = fieldVal
        toRet.push row
      tableau.dataCallback toRet, -1
  )


$(document).ready ->
  $('#inputForm').submit ->
    # This event fires when a button is clicked
    event.preventDefault()
    key = $('#key')
    tab = $('#tab')

    return if !key or !tab
      
    tableau.connectionData = JSON.stringify {key: key[0].value, tab: tab[0].value }
    tableau.connectionName = 'Google Spreadsheet Data'
    tableau.submit()