_ = require 'underscore'

STRING = "string"
INT = "int"
FLOAT = "float"
DATE = "date"
# STRING = tableau.dataTypeEnum.string
# INT = tableau.dataTypeEnum.int
# FLOAT = tableau.dataTypeEnum.float
# DATE = tableau.dataTypeEnum.date
# We need to map the source column data type to tableau column
# data type. This function tries to figure out the type based on
# its value.
guessDataType = (value)-> switch
    when parseInt(value).toString() == value.toString() then INT
    when parseFloat(value).toString() == value.toString() then FLOAT
    when value == "true" || value == "false" || value == true || value == false then INT
    when _.isString(value) then STRING
    when isFinite(new Date(value).getTime()) then DATE
    else STIRNG

getJsonType = (value)-> switch
  when _.isArray(value) then getJsonType(_.first(value))
  when _.isObject(value) then guessDataType(value)
  else guessDataType(value)


module.exports =
  guessDataType: guessDataType
  getJsonType: getJsonType
