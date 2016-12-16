# MongoDB connector

This connector uses the MongoDB Simple REST API to fetch data from
MongoDB and tries to format it from MongoDB's tree-structure to a linear
list of rows.

## Getting MongoDB to cooperate

MongoDB by default does not provide a REST API, and its documentation
recommends that you use some third-party REST provider for complete
functionnality.

To start up MongoDb with the Simple REST API you need to start it with
the ```--rest``` switch, and since we plan on accessing it from a
different host/port combination, we need to also add support for JSONP
with the ```--jsonp``` switch.

The mongod web server by default binds to the 127.0.0.1 interface which
disallows other machines from connecting to it, so we also need to
change the ```bind_address``` property in the configuraion file to
```0.0.0.0``` (this will cause mongod to display a warning that it
already listens to all ips, which is true for the mongod server but not
true for the web server).

After this setup our mongodb should be accessible via

```
http://<server_address>:28017/<database>/<collection>
```



## Getting started with the connector

We'll be using the Starschema WDC Connector Base (ConnectorBase) to
write our connector since it simplifies some basic tasks (like creating
a simple UI).

Also to make our lives easier, we'll use **browserify** to compile the
separate coffeescript source files and JADE templates into a single
javascript file, and it also enables us to use the [CommonJS module
system](http://spinejs.com/docs/commonjs) to be used for dependency
resolution and keeping the global namespace clean.

### Creating the connector

ConnectorBase has a few concepts that may feel different to the usual
WDC development process:

- A connector is built from a number of states/steps (like setup,
  authentication, running the connector), where each state/step has a
  separate representation in the UI (like a setup page, an
  authentication page, etc.)

- The form inputs used by the connector are declared in the template
  for each state (instead of declaring them in the connector code
  itself), so you can keep your connector code DRY

- The connector source code defines the JavaScript to be ran during
  transitions from one state to another. (like get the data from all the
  inputs and call tableau.submit() when transitioning from the *start*
  state to the *run* state.)

So with this in mind, lets go through the mongoDB connector:

We start by importing some necessary libraries:

- JQuery for AJAX
- Underscore for convinience
- Starschema WDC Connector Base

```coffee
$ = require 'jquery'
_ = require 'underscore'
wdc_base = require '../connector_base/starschema_wdc_base.coffee'
```

### Steps and templates

Now we can declare our connector with its two states (*start* to gather
the mongodb connection data and *run* to start the extraction):

```coffee
wdc_base.make_tableau_connector

  steps:
    start:
      template: require './start.jade'
    run_mongo:
      template: require './run.jade'

```

The ```steps``` key describes the steps of the connector. The
```template``` key inside must point to a function that returns an HTML
soup for the UI of that step. We are using JADE to both keep our
templates simple and to allow browserify to compile them directly into
our JavaScript file.

The only necessary state for a connector is **start** which always
represents the startup state of the connector.

Now lets look at the ```start.jade``` template to see how the inputs
work (for brewity only parts of the template are shown here):

```jade

    form
      .row
        .col-sm-3
          label(for="mongodb_host") MongoDB host
          input.form-control(type="text" data-tableau-key="mongodb_host" )

        .col-sm-3
          label(for="mongodb_port") MongoDB port
          input.form-control(type="text" data-tableau-key="mongodb_port" value="28017")

        .col-sm-3
          label(for="mongodb_host") MongoDB Database
          input.form-control(type="text" data-tableau-key="mongodb_db" )

        .col-sm-3
          label(for="mongodb_host") MongoDB Collection
          input.form-control(type="text" data-tableau-key="mongodb_collection" )

      .row
        .col-sm-8
          label(for="mongodb_host") MongoDB additional Parameters
          input.form-control(type="text" data-tableau-key="mongodb_params")

          p
            | Query parameters can be found &nbsp;
            a(href="http://docs.mongodb.org/ecosystem/tools/http-interfaces/#simple-rest-api" target="_blank") in the MongoDB Simple REST API guide.

        .col-sm-2
          label Page size
          input.form-control(type="number" data-tableau-key="page_size" value="1000")


        .col-sm-2
          label Connect
          a.btn.btn-default(href="#" data-state-to="run_mongo") Connect to MongoDB
```

The important parts are the two *data* attributes used here:

- ```data-tableau-key``` tells ConnectorBase that the value of this
  input should be mapped to the key specified by the value of the
  attribute when collecting the inputs for the step (I will explain this in
  more detail a bit further down in the article)

- ```data-state-to``` tells ConnectorBase that when clicking that HTML
  element, a state transition should be triggered to the state
  specified.

### Transitions between steps

How do these inputs and transitions come into play? Lets look a bit
further down the connectors source and look at the transitions of the
mongo connector to find out (still the same object passed to
 ```make_tableau_connector``` ):

```coffee
  #  [...]
  transitions:
    "start > run_mongo": (data)->
      _.extend data, wdc_base.fetch_inputs("#state-start")
      url = "http://#{data.mongodb_host}:#{data.mongodb_port}/#{data.mongodb_db}/#{data.mongodb_collection}"

      # Add the jsonP stuff
      url = "#{url}/?jsonp=#{JSONP_CALLBACK_NAME}"

      # Add some default page size
      url = "#{url}&limit=#{data.page_size}"


      if data.mongodb_params && data.mongodb_params != ""
        url = "#{url}&#{data.mongodb_params}"

      data.url = url

    "enter run_mongo": (data)->
      wdc_base.set_connection_data( data )
      tableau.submit()
```

The state machine powering ConnectorBase passes three parameters to each
transition function:

- ```data``` which is the mutable state of the state machine.
- ```from``` which is the name of state we are coming from
- ```to``` which is the name of the state we are transitioning to

Since we are dealing with javascript, we can safely ignore the from and
to parameters if we arent interested in using them.


### Fetching the values of the inputs

```coffee
  transitions:
    "start > run_mongo": (data)->
      _.extend data, wdc_base.fetch_inputs("#state-start")
```

This first transition (called when transitioning from *start* to
*run_mongo*) gets executed when the user clicks the "Connect to MongoDB"
button on the *start* page.

The ```fetch_inputs(<wrapper_selector>)``` function collects the values of
all inputs marked with ```data-tableau-key``` from the given wrapper
selector into a single object. This object in this case might look
something like this:

```coffee
{
  mongodb_host: '192.168.86.250'
  mongodb_port: '28017'
  mongodb_db: 'test'
  mongodb_collection: 'restaurants'
  mongodb_params: ''

  page_size: '1000'
}
```

By doing a ```_.extend data, wdc_base.fetch_inputs("#state-start")``` we
are appending these key/value pairs to the state machine state so we can
access them in later transitions.


### Creating the MongoDB URL from the inputs

After collecting the inputs, we build our MongoDB url in a few steps
(JSONP_CALLBACK_NAME is just a constant storing the name of the callback
we'll use for JSONP in JQuery):

```coffee
  # Create the basic URL
  url = "http://#{data.mongodb_host}:#{data.mongodb_port}/#{data.mongodb_db}/#{data.mongodb_collection}"

  # Add the jsonP param so we get a JSONP response so we wont get
  # Cross-Site scripting errors
  url = "#{url}/?jsonp=#{JSONP_CALLBACK_NAME}"

  # Add the page size to the URL
  url = "#{url}&limit=#{data.page_size}"


  # If the user provided any additional parameters, add those
  if data.mongodb_params && data.mongodb_params != ""
    url = "#{url}&#{data.mongodb_params}"

  # Finally save the url into our state data
  data.url = url
```

### Starting the extract process

With this completed, we have the URL to connect to, so we'll start the
extraction process using a nice feature of the state machine:

```coffee
    # [...] still in the transitions block

    "enter run_mongo": (data)->
      wdc_base.set_connection_data( data )
      tableau.submit()
```

This transition gets triggered whenever we enter the *run_mongo* state,
AFTER the transitions declared as between two states are ran (like our
previous ```start > run_mongo``` transition), so we can say that
"whenever we enter the run_mongo state, after any in-between transitions
are ran, run this transition handler".

This transition handler uses the convinience function
```set_connection_data(<object>)``` to save the state machine data into
```tableau.connectionData``` as serialized JSON. We can use the
```get_connection_data()``` function to get the deserialized object
back. This keeps the serialization part well abstracted.



### Getting the table Metadata

ConnectorBase calls the methond ```columns(<connection_data>)``` to load
our headers. Here we simply do the work needed and then call
```
tableau.headersCallback()
```

```coffee
  columns: (connection_data)->

    load_jsonp connection_data.url, (data)->
      tableau.abortWithError("No rows available in data") if _.isEmpty(data)

      # get the first row
      first_row = _.first( json_flattener.remap(_.first(data.rows)).rows )

      # Guess the data types of the columns
      datatypes = _.mapObject first_row, (v,k,o)->
       tableauHelpers.guessDataType(v)

      # Call back tableau
      tableau.headersCallback( _.keys(datatypes), _.values(datatypes))
```

There are a few helper methods at work here, so lets go through them
one-by-one:

```coffee
load_jsonp = (url, success_callback)->
  $.ajax
    url: url
    jsonpCallback: JSONP_CALLBACK_NAME
    contentType: "application/json",
    dataType: 'jsonp',
    success: (data, textStatus, request)->
      success_callback(data)
    error: (xhr, ajaxOptions, thrownError)->
      tableau.abortWithError "Error while trying to load '#{url}'. #{thrownError}"
```

This really is only a convinience function so we dont have to repeat
ourselves during the data callback and the header callback. It simply
takes a URL and a callback and either calls the callback with the loaded
data or aborts the extract process in case of a connection problem.


The ```json_flattener.remap(<object>)``` is a more complicated function
that flattens the tree hierarchy of the data from MongoDB to a flat list
of rows. It will be explained in detail in a later article, for now the
important thing is that it takes a (possibly nester) javascript object
and returns an array of flat javascript objects.

The ```guessDataType( <value> )``` function takes a Javascript string
value as input and returns a possible Tableau Datatype for it

```coffee
  # We need to map the source column data type to tableau column
  # data type. This function tries to figure out the type based on
  # its value.
  guessDataType = (value)-> switch
      when parseInt(value).toString() == value.toString() then 'int'
      when parseFloat(value).toString() == value.toString() then 'float'
      when value == "true" || value == "false" || value == true || value == false then 'int'
      when _.isString(value) then 'string'
      when isFinite(new Date(value).getTime()) then 'date'
      else 'string'
```

So we use ```json_flattener.remap``` to flatten the first object
returned by MongoDB and get the field names and types by using
Underscore.js's ```mapObject``` function.


### Loading the data itself


The data loader callback takes almost the exact same shape as the header
loader, except for the pagination logic:

- The function uses the start offset of the next page as the
  ```lastRecordToken``` (or 0 for the first page)

- MongoDB returns the start offset and returned record count as
  ```offset``` and ```total_rows``` in the response, and we use it to
  check if the total_records returned is 0 (in which case we have reached the last page).

- If we arent at the last page, then increment the start offset by the
  returned record count and use this as our new ```lastRecordToken```


```coffee
  rows: (connection_data, lastRecordToken)->
    offset_str = if lastRecordToken == "" then 0 else lastRecordToken
    offseted_url = "#{connection_data.url}&skip=#{offset_str}"

    load_jsonp offseted_url, (data)->

      {offset: offset, rows: rows, total_rows: total_rows} = data

      # when we reached the last page, it is signaled by returning
      # 0 rows
      has_more = (total_rows != 0)
      # the next page is the one after the current
      next_offset = offset + total_rows

      # Remap each row
      tableau_data = for row in rows
        json_flattener.remap(row, null).rows

      # Call back tableau
      tableau.dataCallback(_.flatten(tableau_data), next_offset.toString(), has_more)
```


 
