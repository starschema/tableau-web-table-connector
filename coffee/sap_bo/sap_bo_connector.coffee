$ = require 'jquery'
_ = require 'underscore'
dateFormat = require('dateformat')
helpers = require '../connector_base/tableau_helpers'
wdc_base = require '../connector_base/starschema_wdc_base.coffee'

PROXY_SERVER_CONFIG =
	protocol: 'http'

rowConverter = {}

# Transforms type to tableau type
transformType = (type) ->
    switch type
        when 'STRING' then tableau.dataTypeEnum.string
        when 'DOUBLE', 'FLOAT' then  tableau.dataTypeEnum.float
        when 'INT32', 'INT64', 'UINT32', 'UINT64' then tableau.dataTypeEnum.int
        when 'DATE' then tableau.dataTypeEnum.date
        when 'DATETIME' then tableau.dataTypeEnum.datetime
        else tableau.dataTypeEnum.string


# Attempts to convert a list of fields to a table schema compatible
# with tableau
toTableauSchema = (fields)->
    fields.map (field)-> {id: sanitizeId(field.name), dataType: transformType(field.type) }

# Creates a converter from the given schema
makeRowConverter = (schema) ->
    converters = {}
    Object.keys(schema).map (k)->
        converters[schema[k].id] = switch schema[k].dataType
            when tableau.dataTypeEnum.datetime then (x) -> dateFormat(new Date(x), "yyyy-mm-dd HH:MM:ss")
            when tableau.dataTypeEnum.date then (x) -> dateFormat(new Date(x), "yyyy-mm-dd")
            else (x)-> x
    (row) ->
        Object.keys(row).map (k)->
            converters[sanitizeId k](row[k])

#  Replaces any non-id characters with an underscore
sanitizeId = (name)->
  name.replace(/[^a-zA-Z0-9_]/g, '_')

wdc_base.make_tableau_connector
    steps:
        start:
            template: require './start.jade'
        configuration:
            template: require './configuration.jade'
        run:
            template: require './run.jade'

    transitions:
        "enter start": (data)->
          if data.error
            $('#error').show().text(data.error)
          else
            $('#error').hide().text()

        "start > configuration": (data) ->
            _.extend data, wdc_base.fetch_inputs("#state-start")

        "configuration > run": (data) ->
            _.extend data, wdc_base.fetch_inputs("#state-configuration")

        "enter configuration": (data, from,to, transitionTo) ->
            url = "#{PROXY_SERVER_CONFIG.protocol}://#{window.location.host}/sap/tablelist"
            $.ajax
                url: url
                dataType: 'json'
                data:
                    "wsdl": data.wsdl
                success: (data, textStatus, request) ->
                    for table in data
                        $("<option>").val(table).text(table).appendTo('#tables')
                error: (o, statusStr, err) ->
                    console.log o
                    console.error err
                    transitionTo "start", error: "While fetching '#{url}':\n#{o.responseText}\n#{err}"

        "enter run": (data) ->
            tableau.password = JSON.stringify
                credentials:
                    username: data.auth_username
                    password: data.auth_password

            delete data.auth_username
            delete data.auth_password

            wdc_base.set_connection_data data
            tableau.submit()

    columns: (connection_data, schemaCallback) ->
        connectionUrl = "#{PROXY_SERVER_CONFIG.protocol}://#{window.location.host}/sap/tabledefinitions"
        config = JSON.parse(tableau.password)
        config.wsdl = connection_data.wsdl
        config.table = connection_data.table
        xhr_params =
            url: connectionUrl
            dataType: 'json'
            data: config
            success: (data, textStatus, request)->
                if data?.length > 0
                    schema = toTableauSchema(data)
                    rowConverter = makeRowConverter schema
                    schemaCallback [
                      id: sanitizeId(config.table),
                      columns: schema
                    ]
            error: (err) ->
                console.error "Error while loading headers from `#{connectionUrl}`:", err
                tableau.abortWithError err.responseText
        $.ajax xhr_params

    rows: (connection_data, table, doneCallback) ->
        connectionUrl = window.location.protocol + '//' + window.location.host + '/sap/tablerows'
        config = JSON.parse(tableau.password)
        config.wsdl = connection_data.wsdl
        config.table = connection_data.table
        _.extend connection_data, JSON.parse(tableau.password)
        xhr_params =
            url: connectionUrl
            dataType: 'json'
            data: config
            success: (data, textStatus, request)->
              if data.length > 0
                table.appendRows(data.map(rowConverter))

              doneCallback()
            error: (err) ->
                console.error "Error while loading rows from `#{connectionUrl}`:", err
                tableau.abortWithError err.responseText
        $.ajax xhr_params
