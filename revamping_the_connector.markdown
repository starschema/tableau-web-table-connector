# Preparations

To make it easier to write nice code, we'll be using the
[Underscore.js][underscore] library, which provides many useful small
utility higher-order functions that have high quality implementations.
The [production version (minified, g-zipped)][us-mini] clocks in at 5
kilobytes, but for our purposes, the [development version][us-js]
provides a nicer debugging experience, and we can change it in
production if necessary.


# Scoping the code

The first order of the day is to make the connector work without having
to compile it with the ```--bare``` command line option (or using the
web-based coffescript compiler).

For this to work, we have to export all the event handlers used by
tableau into the global namespace. To start out our exploration of
underscore, we'll use the **[extend][_extend](destination, *sources)]**
function, which merges one or more objects into the first argument
passed (for details, see the underscore documentation).

At the end of the file, where all my handlers are already declared:


```coffee
_.extend window,
  init: init
  shutdown: shutdown
  getTableData: getTableData
  getColumnHeaders: getColumnHeaders
```

# Refactoring out the AJAX code

Both the column header and the table data getters use the same AJAX
calls to the Google Docs server, so lets move it out to its own
function, and do some logging for the development environment. We'll
pass the success handler to this function, and hopefully we can add some
nice error handling later on.


```coffee
# Wraps up our ajax requests to Google Docs
#
# *on_success* is called with the  success handler
spreadSheetAjax = (on_success)->
  url = getConnectionURL( JSON.parse( tableau.connectionData) )
  tableau.addWhiteListEntry 'http', 'spreadsheets.google.com'
  tableau.log "Starting connection to #{url}"
  $.ajax( url: url, dataType: 'json', success: (res...)->on_success(res...))

```

# Rewriting the column header loader

First we'll try to think of the data coming in and the data coming out:

#### The input

- google docs gives us the spreadsheet as: { feed: { entry: [ <rows...>  ] }...}
- the rows are: {..."gsx$<column>":{$t:<value>}}

### The output

- tableau expects the column headers to be [<names...>]
- tableau expects the column types to be [<type names...>]

So the transformations we need to make are:

- get the first row returned
- throw away the keys not starting with "gsx$"
- Then transform this result set
  - the column names are the keys left minus the "gsx$" prefix
  - the column types are the types of the values left, which themselves
    are boxed in the "$t" field


#### Getting the first row returned

Lets start revamping the getColumnHeaders function, and make use of the
revamped spreadSheetAjax function:

```coffee

# Tableau callback to get the headers from the spreadsheet
getColumnHeaders = ->
  # Do the AJAX call
  spreadSheetAjax (res)->
    entry = res.feed.entry[0]
```


#### Finding the right keys

Without any preparations, lets write a module-level helper function that tests
a key if its a key we are interested in. We make it module-level because
we want to re-use it later.

Its signature (passing the value then the key) might seem strange at
first, but this signature is the way underscore expects our functions to
be (more on this later):

```coffee
keyFilter = (val,key)-> key[0..3] == 'gsx$'
```

So now we can use the [pick(obj,pred)][_pick] method provided by underscore to
grab the keys we are interested in:

```coffee
columns = _.pick(entry, keyFilter)
```

Now we have an object with only the fields we care about.


#### Transforming between formats

The next step might seem a little compicated, but its really simple,
once you get down to the core of it:

- we need to transform the keys of the object
- we need to transform the values of the object

We can either

1 transform the object in key-value pairs or
2 we can transform the keys and the values separately

We'll go with option 1, because it will result in code we can reuse
later when we're getting the table data, where we need to return an
object for each row.

Sadly, underscore does not come with a function built-in that can
transform both the keys and the values of an object, but we can write
this little routine, which will come handy on multiple occasions later.
To signal its utilitarian nature, I'm putting it in the underscore
namespace:


```coffee
# Allows fn to transform both the keys and values of the object.
#
# Like other underscore functions, fn takes a (value,key) as input and should
# return an object whos keys will be added to the output object.
#
# Returns an object containing all the keys from each iteration of fn,
# overwriting existing keys as the iteration progresses.
_.remapObject = (obj,fn)->
  # _.extend takes any number of arguments and the reducer
  # function gets called with more then 2 arguments, so it
  # whould merge the excess args.
  _.reduce( _.map(obj,fn), ((m,o)->_.extend(m,o)), {})

```

It works by first [mapping][_map] ```fn``` on each (value key) pair of
```obj``` , which (if fn correctly returns an object) results in a list
of objects, which we then [combine][_reduce] using the
[_.extend][_extend] function, which we already met.

Since most of the time we want to return a simple pair of transformed
name and transformed value, lets create a little function that does
exactly this, because there is no syntax for this in JavaScript and it
can make our code ugly:

```coffee
# Shortcut to create a brand new object from a key-value pair
_.makePair = (key,value)-> o={};o[key]=value;o

```


So with these tools in hand, we can tackle the column header
transformation. We start by extracting the data type guesser:

```coffee
# We need to map the google column data to tableau column
# data
guess_data_type = (value)-> switch
  when parseInt(value).toString() == value then 'int'
  when parseFloat(value).toString() == value then 'float'
  when isFinite(new Date(value).getTime()) then 'date'
  else 'string'
```


And writing a small function to remove the prefixes:

```coffee
# Remove the magic string prefix
removeKeyPrefix = (key)-> key[4..]
```


With this in hand, we can define the transform function that takes a
cell from Google Spreadsheet as input and gives us a field name-field
type pair:


```coffee
# Each cell needs its key prefix removed and its
# value can be found in the $t field of the spreadsheet cell,
# lets use guessDataType to find its type
cellRemapper = (value,key)->
  _.makePair(removeKeyPrefix(key), guessDataType(value.$t))
```

Now we can use this function to transform the previously filtered object
with only the right fields present.

```coffee
columns = _.pick(entry, keyFilter)
typeMap = _.remapObject( columns, cellRemapper )
```

And we can call the tableau callback with the field names and types
using underscores [keys][_keys] and [values][_values] method:

```coffee
tableau.headersCallback _.keys(typeMap), _.values(typeMap)
```


### Rewriting the table data loader

The input-output constraints are somewhat similar, I'll copy them here
just for the sake of completeness:

#### The input

- google docs gives us the spreadsheet as: { feed: { entry: [ <rows...>  ] }...}
- the rows are: {..."gsx$<column>":{$t:<value>}}

### The output

- tableau expects the table to be [<rows...>]
- tableau expects the table rows to be { <key>:<value> }


Using the same concepts as before, the only real difference for the
table data is that we need to process all rows not just the first, and
that we need to extract the value of the cell instead of the type, so
our code looks something like this:




[underscore]: http://underscorejs.org
[us-mini]: http://underscorejs.org/underscore-min.js
[us-js]: http://underscorejs.org/underscore.js
[_extend]: http://underscorejs.org/#extend
[_pick]: http://underscorejs.org/#pick
[_map]: http://underscorejs.org/#map
[_reduce]: http://underscorejs.org/#reduce
