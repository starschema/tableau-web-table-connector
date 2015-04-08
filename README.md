# Starschema Tableau Web Table Connector

A mini framework for writing Tableau Web Data Connector.

## Using the connector in Tableau

NOTE: You'll need Tableau 9.0 with the Web Data Connector licensed.

The connector is already compiled into a single javascript file, so you
can use the connector right out of the box:

  - Set up an http server and point it to the dist folder
  - Load the index.html file in the dist folder in Tableau



## Building a new connector


Take a look at the __providers__ folder: the __providers.coffee__ file
tells the framework which providers are available. To add a new one, add
its key and require it.

A provider is a javascript object that has the following three fields:

  - name: The name displayed on the user interface

  - template: A function that takes no arguments and returns a string
    with the contents of the setup page for this provider.

  - loader: A function that takes an error handler function and returns
    a loader.

### The loader function

The loader by default is a function that takes a parameter object and a
callback function, loads the data, deserializes it to Tableau's format
and calls the callback with the object after competition.

The framework helps here by allowing you to use the

```coffee
tableSource.loader(ajaxParameterGenerator, deserializer, errorHandler)
```

function which sets up a loader, all you have to do is to provide a
function for the ajax parameters (takes the same params object, and
returns options for the JQuery AJAX request. The only necessary option
to return is the url, but you can use any option you's pass to ```$.ajax```

The deserializer takes the raw text response, and turns it into a list
of JavaScript objects.

### Templates

The framework uses JADE throughout, so you can require('<template path>')
them, and they get compiled into the resulting JavaScript by browserify.

To allow parameters to pass from the setup screen to the
ajaxParameterGenerator and the deserializer of the provider, add the
HTML data-attribute ```data-tableau-key="<name of the property>"```
to the inputs whose value you'd like to add to the parameters object
passed to these functions.


### Building the connector

```sh
./build.sh
```

This script runs browserify, resolves the imports and concatenates the
javascripts.

A full Grunt-based build is in the works.


### Cross-site scripting protection

To allow loading from remote URLs, the target server has to reply with
the  ```Access-Control-Allow-Origin``` header set to ```*``` for the
preview function to work.
