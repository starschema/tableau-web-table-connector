_ = require 'underscore'
tableSource = require '../../coffee/lib/table_source'


_.extend exports,
  name: "Google Spreadsheet Data"
  template: require './form.jade'

  loader: (errorHandler=_.noop)->

    # Our ajax parameters are simple
    ajaxParameterGenerator = (params)->
      url: "http://spreadsheets.google.com/feeds/list/" +
            "#{params.key}/#{params.tab}/public/values?alt=json"
      dataType: 'json'

    deserializer = (res, params, callback)->
      callback _.map res.feed.entry, (row)->
        _.chain(row)
          .pick( (val,key)-> key[0..3] == 'gsx$')
          .remapObject( (val,key)-> _.makePair(key[4..],val.$t))
          .value()


    tableSource.loader(ajaxParameterGenerator, deserializer, errorHandler)

