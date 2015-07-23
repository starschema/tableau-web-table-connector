# Building the twitter client

```
npm install
./build-twitter.sh
```

this copies the resources and builds the client using browserify.

# Running the twitter client / server

```
coffee coffee/twitter_connector/twitter_auth_server.coffee
```

Then navigate to ```http://localhost:3000/twitter.html``` in the
Simulator / Tableau.
