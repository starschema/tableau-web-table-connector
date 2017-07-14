_ = require 'underscore'

class Table
  constructor: (@rows=[])->

  add_row: (row_data)->
    @rows.push row_data



merge_table_pair = (t1, t2)->
  a = t1.rows
  b = t2.rows
  o = new Table

  for a_row in a
    for b_row in b
      o.add_row _.extend({}, a_row, b_row)

  o


merge_tables = (t1, tables...)->
  return t1  if _.isEmpty(tables)
  return merge_table_pair(t1, tables[0]) if tables.length == 1

  merge_table_pair(t1, merge_tables(tables...))



remap = (obj, base_key=null)->
  base_row = {}

  # The function to retrieve the key
  key = if base_key then  (k) -> "#{base_key}_#{k}" else (k) -> k

  # First add primitive values
  for k,v of obj
    if _.isString(v) or _.isNumber(v)
      base_row[key(k)] = v

  base_table = new Table([base_row])
  children = []
  choices = {}

  # For each attribute
  for k,v of obj
    switch

      # Add arrays as choices for the key
      # recursively
      when _.isArray(v)

        table_out = new Table

        for element in v
          for row in remap(element, key(k)).rows
            table_out.add_row(row)
        choices[k] = table_out

      # Add objects as extensions for their key
      # recursively
      when _.isObject(v)
        children.push remap(v, key(k))

  # Merge the extensions to the base attributes after
  # all their children and choice tables are already extended
  base_out = merge_tables( base_table, children... )

  # Then finally merge all the choices to the extended base table
  # ( so the attributes coming from the extensions are mapped across
  # all choices here)
  for k,v of choices
    base_out = merge_tables( base_out, v)

  base_out

_.extend module.exports,
  remap: remap

