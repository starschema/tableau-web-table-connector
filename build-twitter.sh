#!/bin/sh -Eux

BOOTSTRAP_DIR=./dist/bootstrap/3.3.5
JQUERY_DIR=./dist/jquery/1.11.1

mkdir -p ${BOOTSTRAP_DIR}
cp -Rv resources/bootstrap-3.3.5-dist/* ${BOOTSTRAP_DIR}

mkdir -p ${JQUERY_DIR}
cp resources/jquery/1.11.1/* ${JQUERY_DIR}

cp resources/tableau-wdc-js/tableauwdc-1.1.0.js ./dist
cp resources/twitter.html ./dist
browserify --extension=".coffee"  coffee/twitter_connector/twitter_connector.coffee > dist/twdc-twitter.js

#node dist/twdc-twitter.js
