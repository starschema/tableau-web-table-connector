express = require 'express'
Twitter = require('twitter')
http_request = require 'request'
sap = require 'bobj-access'

app = express()

console.log "startup"


TWITTER_GET_OAUTH_TOKEN_URL = "https://api.twitter.com/oauth2/token"

try
    keys = require './twitter_keys.coffee'

    client = new Twitter
      consumer_key: keys.CONSUMER_KEY,
      consumer_secret: keys.CONSUMER_SECRET,
      access_token_key: keys.ACCESS_TOKEN,
      access_token_secret: keys.ACCESS_TOKEN_SECRET

    app.get '/search', (req, res)->
      console.log "--> #{req.path} -- #{JSON.stringify(req.query)}"
      #res.send("OK")
      #return
      client.get 'search/tweets', req.query, (error, tweets, response)->
        if error
          console.log "<=== Error: #{error}"
          res.status(500).send("<h1>Error: #{JSON.stringify(error)}</h1>")

        tweet_json = JSON.stringify(tweets)
        console.log "<-- OK #{tweet_json.length} bytes"

        res.setHeader('Content-Type', 'application/json')
        res.send(tweet_json)
catch ex
    console.log "Failed to initialize twitter server, but it doesn't affect other functionalities.", ex


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
    sap.getTableData req.query.wsdl, req.query.credentials, req.query.table, (err, tables) ->
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

  console.log('Twitter WDC Connection Server listening at http://%s:%s', host, port)
