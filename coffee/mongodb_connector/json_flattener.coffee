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


orig =
  name: "Henry Rollins"
  attributes: {
    weight: 75
    height: 175
    tags: [
      { text:"Healthy"}
      { text: "Unorthodox"}
    ]
  }
  bands: [
    { band: "Black flag", albums: [ {title: "BF Album I", year: 1981}, {title: "BF Album II", year: 1982}, {title: "BF Album III", year: 1983} ] }
    { band: "Henry Rollins band", albums: [{title: "HR Album I", year: 1981}, {title: "HR Album II", year: 1982}, {title: "HR Album III", year: 1983} ] }
  ]



remap = (base_key, obj)->
  base_row = {}
  key = (k) -> "#{base_key}.#{k}"
  # 1 add primitive values
  for k,v of obj
    if _.isString(v) or _.isNumber(v)
      base_row[key(k)] = v

  base_table = new Table([base_row])
  children = []
  choices = {}

  for k,v of obj
    switch
      when _.isArray(v)

        table_out = new Table

        for element in v
          for row in remap(key(k), element).rows
            table_out.add_row(row)
        choices[k] = table_out

      when _.isObject(v)
        children.push remap(key(k), v)

  base_out = merge_tables( base_table, children... )

  for k,v of choices
    base_out = merge_tables( base_out, v)

  base_out

black_flag_band = new Table([{band:"Black flag"}])
black_flag_albums = new Table([{title: "BF Album I", year: 1981}, {title: "BF Album II", year: 1982}, {title: "BF Album III", year: 1983} ])

hr_band = new Table([{band: "Henry Rollins band"}])
hr_albums = new Table([{title: "HR Album I", year: 1981}, {title: "HR Album II", year: 1982}, {title: "HR Album III", year: 1983} ])

artist = new Table([{name: "Henry Rollins"}])

console.log remap("artist", orig)
