#!/bin/sh -Eux

cp resources/tableau-wdc-js/tableauwdc-1.1.0.js ./dist
cp resources/index.html ./dist
browserify --extension=".coffee"  coffee/github_commits/twdc-github-commits.coffee > dist/twdc-github-commits.js
