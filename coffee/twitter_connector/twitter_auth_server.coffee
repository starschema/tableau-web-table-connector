express = require 'express'
Twitter = require('twitter')
http_request = require 'request'

app = express()

console.log "startup"


TWITTER_GET_OAUTH_TOKEN_URL = "https://api.twitter.com/oauth2/token"

CONSUMER_KEY =	"kWyxiJH90fDiHGFv372v6g1OZ"
CONSUMER_SECRET =	"yGxQNtqQL2KJXWmBYdJolG3y5I6YEmZOT3WXPbWNEzmlBBXPAf"
ACCESS_TOKEN = "80296682-A2qWP5Kb8CMdnFKck2Xx8rWZU913wT9TpueFNMZdD"
ACCESS_TOKEN_SECRET="lQCRodhGfm7aiWaUraqFhQZ4r5oPKJhAe07yep7lpBluO"


client = new Twitter
  consumer_key: CONSUMER_KEY,
  consumer_secret: CONSUMER_SECRET,
  access_token_key: ACCESS_TOKEN,
  access_token_secret: ACCESS_TOKEN_SECRET

app.get '/', (req, res)-> res.send("<h1>Hello</h1>")

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

# serve the static files of the connector
app.use(express.static('dist'))


server = app.listen 3000, ->
  host = server.address().address
  port = server.address().port

  console.log('Twitter WDC Connection Server listening at http://%s:%s', host, port)
