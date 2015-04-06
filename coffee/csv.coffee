
csvLoader = (errorHandler=_.noop)->

  # Our ajax parameters are simple
  ajaxParameterGenerator = (params)->
    url: params.url #"http://spreadsheets.google.com/feeds/list/" +
          #"#{params.key}/default/public/values?alt=json"
    dataType: 'json'

  deserializer = (res)->
    _.map res.feed.entry, (row)->
      _.chain(row)
        .pick( (val,key)-> key[0..3] == 'gsx$')
        .remapObject( (val,key)-> _.makePair(key[4..],val.$t))
        .value()


  loader(ajaxParameterGenerator, deserializer, errorHandler)


root = exports ? this
_.extend root,
  csvLoader: csvLoader
