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

To access the REST API from a different machine you also need to change
the ```bind_ip``` configuration property in your mongodb configuration
form 127.0.0.1 (the default that comes with most mongodb packages) to
0.0.0.0

After changing the bind address, starting mongod will issue a warning:

```
warning: bind_ip of 0.0.0.0 is unnecessary; listens on all ips by default
```

but this warning is a lie when it comes to the web interface used for
the REST API.


Then build the mongodb connector:

```
./build-mongodb.sh
```

this copies the resources and builds the client using browserify and
places the results in the ```dist``` folder.


Then fire up a web server in the dist directory and the mongodb
connector should be accessible with ```mongodb.html```.
