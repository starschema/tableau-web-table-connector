_ = require 'underscore'
csv = require 'csv'

tableSource = require '../../coffee/lib/table_source'

_.extend exports,
  name: "CSV Data"
  template: require './form.jade'
  loader: (errorHandler=_.noop)->
    # Our ajax parameters are simple
    ajaxParameterGenerator = (params)->
      url: params.url
      contentType: "text/html;charset=#{params.charset}"

    deserializer = (res, params, callback)->
      opts = _.defaults params,
        quote: '"'
        delimiter: ','
        columns: true
        auto_parse: true

      csv.parse res, opts, (err,data)-> callback(data)




    tableSource.loader(ajaxParameterGenerator, deserializer, errorHandler)


