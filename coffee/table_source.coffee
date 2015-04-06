
# *ajaxParameterGenerator*   : (params)->{...}
#     Takes an object of parameters (maybe from a form) and returns
#     an object of jQuery ajax options containing at least the url.
#
# *deserializer*  : (text)->obj
#   Takes a string and returns the table represented by it.
#
# Returns a function that takes (params, callback) and executes
# the ajax request and calls callback with the deserialized data
loader = (ajaxParameterGenerator, deserializer, errorHandler=_.noop)->
  (params, callback)->
    ajaxOpts = _.extend {}, ajaxParameterGenerator(params),
      success: (data, textStatus, jqXHR)-> callback(deserializer(data))
      error: (args...) -> errorHandler(args...)
    tableau.log("Starting download: #{JSON.stringify(ajaxOpts)}")
    $.ajax ajaxOpts

# Provider:
# ---------
#
# provider = (parameters)-> [url, dataType, deserializer]



# We need to map the source column data type to tableau column
# data type. This function tries to figure out the type based on
# its value.
guessDataType = (value)-> switch
  when parseInt(value).toString() == value then 'int'
  when parseFloat(value).toString() == value then 'float'
  when isFinite(new Date(value).getTime()) then 'date'
  else 'string'


# Gets a list of column objects
getColumns = (rows)->
  _.mapObject( rows[0], (v,k)->{name:k, import:true, type:guessDataType(v)})


root = exports ? this
_.extend root,
  loader: loader
  getColumns: getColumns
