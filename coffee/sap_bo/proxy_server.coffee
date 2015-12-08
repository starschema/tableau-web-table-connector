express = require 'express'
cors = require 'cors'
http_request = require 'request'
sap = require 'bobj-access'

app = express()
app.use(cors())


app.get '/', (req, res)-> res.send("<h1>Hello</h1>")

app.get '/sap/tablelist', (req, res) ->
    sap.getTableList req.query.wsdl, (err, tableList) ->
        unless err?
            res.json tableList
            console.log "Table list response sent", tableList
        else
            res.status(500).send()

app.get '/sap/tabledefinitions', (req, res) ->
    sap.getFields req.query.wsdl, req.query.credentials, req.query.table, (err, tables) ->
        unless err?
            res.json tables
            console.log "Table definition response sent. table: ", req.query.table
        else
            res.status(500).send()

app.get '/sap/tablerows', (req, res) ->
    sap.getTableData req.query.wsdl, req.query.credentials, req.query.table, {}, (err, tables) ->
        unless err?
            res.json tables
            console.log "Data Response sent.table: ", req.query.table
        else
            res.status(500).send()

# serve the static files of the connector
app.use(express.static('dist'))

server = app.listen 3000, ->
  host = server.address().address
  port = server.address().port

  console.log('SAP BO Connection Server listening at http://%s:%s', host, port)
