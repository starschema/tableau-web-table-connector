_ = require 'underscore'

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

getJsonType = (value)-> switch
  when _.isArray(value) then getJsonType(_.first(value))
  when _.isObject(value) then guessDataType(value)
  else guessDataType(value)


module.exports =
  guessDataType: guessDataType
  getJsonType: getJsonType
