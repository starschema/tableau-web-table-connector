express = require 'express'
cors = require 'cors'
http_request = require 'request'
sap = require 'bobj-access'
fs = require('fs')
https = require('https')
http = require('http')

SERVER_CONFIG =
  ssl: true
  privateKey: 'cert.key'
  certificate: 'cert.crt'
  port:3000


app = express()
app.use(cors())





app.get '/', (req, res)-> res.send("<h1>Hello</h1>")

app.get '/sap/tablelist', (req, res) ->
    sap.getTableList req.query.wsdl, (err, tableList) ->
        unless err?
            res.json tableList
            console.log "Table list response sent", tableList
        else
            console.log("ERROR:", err, err.stack)
            res.status(500).send()

app.get '/sap/tabledefinitions', (req, res) ->
    sap.getFields req.query.wsdl, req.query.credentials, req.query.table, (err, tables) ->
        unless err?
            res.json tables
            console.log "Table definition response sent. table: ", req.query.table
        else
            console.log("ERROR:", err, err.stack)
            res.status(500).send()

app.get '/sap/tablerows', (req, res) ->
    sap.getTableData req.query.wsdl, req.query.credentials, req.query.table, {}, (err, tables) ->
        unless err?
            res.json tables
            console.log "Data Response sent.table: ", req.query.table
        else
            console.log("ERROR:", err, err.stack)
            res.status(500).send()

# serve the static files of the connector
app.use(express.static('dist'))


if SERVER_CONFIG.ssl
    fsr = fs.readFileSync
    https.createServer({key: fsr(SERVER_CONFIG.privateKey), cert: fsr(SERVER_CONFIG.certificate)}, app).listen SERVER_CONFIG.port, ()->
      console.log("SAP BO server listening on port https " + SERVER_CONFIG.port);


else
    server = app.listen SERVER_CONFIG.port, ->
      host = server.address().address
      port = server.address().port

    console.log('SAP BO Connection Server listening at http://%s:%s', host, port)
