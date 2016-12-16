$ = require 'jquery'
_ = require 'underscore'
wdc_base = require '../connector_base/starschema_wdc_base.coffee'

transformType = (type) ->
    switch type
        when 'STRING' then 'string'
        when 'DOUBLE', 'FLOAT' then 'float'
        when 'INT32', 'INT64', 'UINT32', 'UINT64' then 'int'
        when 'DATE' then 'date'
        else 'string'

fieldNames = (fields) ->
    fields.map (field) ->
        field.name

fieldTypes = (fields) ->
    fields.map (field) ->
        transformType field.type

wdc_base.make_tableau_connector
    steps:
        start:
            template: require './start.jade'
        configuration:
            template: require './configuration.jade'
        run:
            template: require './run.jade'

    transitions:
        "start > configuration": (data) ->
            _.extend data, wdc_base.fetch_inputs("#state-start")

        "configuration > run": (data) ->
            _.extend data, wdc_base.fetch_inputs("#state-configuration")

        "enter configuration": (data) ->
            $.ajax
                url: "#{window.location.protocol}//#{window.location.host}/sap/tablelist"
                dataType: 'json'
                data:
                    "wsdl": data.wsdl
                success: (data, textStatus, request) ->
                    for table in data
                        $("<option>").val(table).text(table).appendTo('#tables');
                error: (err) ->
                    console.log "Error:", err

        "enter run": (data) ->
            tableau.password = JSON.stringify
                credentials:
                    username: data.auth_username
                    password: data.auth_password

            delete data.auth_username
            delete data.auth_password

            wdc_base.set_connection_data data
            tableau.submit()

    columns: (connection_data) ->
        connectionUrl = window.location.protocol + '//' + window.location.host + '/sap/tabledefinitions'
        config = JSON.parse(tableau.password)
        config.wsdl = connection_data.wsdl
        config.table = connection_data.table
        xhr_params =
            url: connectionUrl
            dataType: 'json'
            data: config
            success: (data, textStatus, request)->
                if data?.length > 0
                    tableau.headersCallback fieldNames(data), fieldTypes(data)
            error: (err) ->
                console.log "Error:", err
        $.ajax xhr_params

    rows: (connection_data) ->
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
                tableau.dataCallback data, "", false
            error: (err) ->
                console.log "Rows Error:", err
        $.ajax xhr_params
