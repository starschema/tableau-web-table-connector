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

# Building the mongo/raw json client

Connecting to mongodb using the Simple REST API requires starting the
mongod server with the ```--rest``` and ```--jsonp``` command line
switches to enable the REST API and enable the connector to load data
through JSONP.


For example on Ubuntu this may mean:

```
mongod --config /etc/mongodb.conf --rest --jsonp
```

Then build the mongodb connector:

```
./build-mongodb.sh
```

this copies the resources and builds the client using browserify and
places the results in the ```dist``` folder.
