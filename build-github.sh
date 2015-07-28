#!/bin/sh -Eux

cp resources/tableau-wdc-js/tableauwdc-1.1.0.js ./dist
cp resources/github.html ./dist
browserify --extension=".coffee"  coffee/github_commits/github_connector.coffee > dist/twdc_github_connector.js
