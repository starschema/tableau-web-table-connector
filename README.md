# Starschema Tableau Web Table Connector (WDC) Toolkit / ConnectorBase [![Build Status](https://travis-ci.org/starschema/tableau-web-table-connector.svg)](https://travis-ci.org/starschema/tableau-web-table-connector)

Starschema's Tableau Web Table Connector Toolkit enables you to develop Web Data Connectors in CoffeeScript more easily, elegantly. It comes with sample connectors for **SAP BusinessObjects. Twitter, MongoDB, Github and generic CSV**. 

The framework (or as we call _ConnectorBase_) has a few concepts that may feel different to the usual WDC development process:

 - A connector is built from a number of states/steps (like setup, authentication, running the connector), where each state/step has a separate representation in the UI (like a setup page, an authentication page, etc.)

 - The form inputs used by the connector are declared in the template for each state (instead of declaring them in the connector code itself), so you can keep your connector code DRY

 - The connector source code defines the JavaScript to be ran during transitions from one state to another. (like get the data from all the inputs and call tableau.submit() when transitioning from the start state to the run state.)

# Business Objects connector


![](http://www.virtdb.com/images/bo-wdc-tableau.gif)

## Building the connector

You should never trust any tableau connector on the internet. Check the source codes before you deploy or run anything on your environment. Therefore we don't provide any "prebuilt" connector, you should do it for yourselves. 

### The necessary steps to compile

- download node.js and install it (https://nodejs.org/en/) 
- Update NPM by typing "npm install npm -g"
- Install Coffee "npm install -g coffee-script" (CoffeeScript is a little language that compiles into JavaScript.)
- Download the tableau-web-table-connector zip, and extract into a directory
- Open a command shell as Administrator
- run "npm install" from the administrator command shell while in the extracted directory
- run "build-sap-bo.sh" from the administrator command shell while in the extracted directory
- run "coffee coffee/sap_bo/proxy_server.coffee" from the administrator command shell while in the extracted directory


this copies the resources and builds the client using browserify. For more information on how to use SAP BusinessObjects connection [check out this article](http://databoss.starschema.net/accessing-sap-businessobjects-from-tableau-using-web-data-connector/). 

## Running the BO proxy web service

```
coffee coffee/sap_bo/proxy_server.coffee
```

Then navigate to ```http://localhost:3000/sapbo.html``` in the
Simulator / Tableau. 

# Twitter Client

## Building the twitter client

```
npm install
./build-twitter.sh
```

this copies the resources and builds the client using browserify.

## Running the twitter client / server

```
coffee coffee/twitter_connector/twitter_auth_server.coffee
```

Then navigate to ```http://localhost:3000/twitter.html``` in the
Simulator / Tableau.

# MongoDB / raw JSON client

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


# CSV Connector

## Building the CSV connector

```
# Linux
./build-csv.sh

# Windows
build-csv.bat
```

## Using the CSV Connector

Copy the built files in the `dist` folder to the root of your webserver, then open `csv.html` in your browser.


