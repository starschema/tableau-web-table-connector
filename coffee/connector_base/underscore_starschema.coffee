_ = require 'underscore'

toArr = (e)-> [e]

byKey = (k)-> (e)->e[k]

combineReduction = (memo,a)->
  return memo if _.isEmpty(a)
  return _.map(a,toArr) if _.isEmpty(memo)
  o = []
  for ae in a
    for row in memo
      o.push [row...,ae]
  o


DEFAULT_FILTER_MAP_FN = (v,k,o)-> [k,v]

_.mixin
  # Returns a function that steps through the elements of a collection
  # returning the next element on each successive call.
  iteratorFor: (coll)->
    idx = 0
    ()-> if coll.length > idx then coll[idx++] else null


  # Takes an index or key and returns a function that tries to get
  # that key from the passed in collection or object
  nth: byKey
  byKey: byKey


  combineReduction: combineReduction

  # Returns the combination of any number of arrays
  combinationsOf: (colls)->
    # Handle edge cases
    return [] if colls.length == 0
    return [colls[0]] if colls.length == 1



    _.reduce colls, combineReduction, []

  # Allows fn to transform both the keys and values of the object.
  #
  # Like other underscore functions, fn takes a (value,key) as input and should
  # return an object whos keys will be added to the output object.
  #
  # Returns an object containing all the keys from each iteration of fn,
  # overwriting existing keys as the iteration progresses.
  remapObject: (obj,fn)->
    # _.extend takes any number of arguments and the reducer
    # function gets called with more then 2 arguments, so it
    # whould merge them
    _.extend( {}, _.map(obj,fn)...)

  # Shortcut to create a brand new object from a key-value pair
  makePair: (key,value)-> o={};o[key]=value;o

  filterObject: (obj, filterFn, tranformFn=DEFAULT_FILTER_MAP_FN)->
    o = {}
    for k, v of obj
      continue unless filterFn(v,k,obj)
      tmp = tranformFn(v,k,obj)
      o[tmp[0]] = tmp[1]

    o




# Re-export undescore for easier importing
module.exports = _
