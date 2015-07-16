connector_base = require '../connector_base/connector_base.coffee'

init_connector (has)->

  has.template 'source.jade'

  has.input 'string', 'username'
  has.input 'string', 'reponame'

