#!/bin/sh -Eux

#find coffee/ -type f -name "*.jade" | xargs jade
#find coffee/ -type f -name "*.coffee" | xargs coffee --compile --output js

#coffee --compile --output . GoogleSpreadsheetEspresso.coffee
#coffee --compile --output js coffee/**/*/*.coffee
browserify --extension=".coffee"  coffee/table_connector.coffee > dist/table-loader.js
