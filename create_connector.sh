#!/bin/sh -Ex 

cp -Rp coffee/template coffee/$1
mv coffee/$1/connector.coffee coffee/$1/${1}_connector.coffee
cp resources/template.html resources/$1.html

sed -i'' "s/CONNECTORNAME/$1/" resources/$1.html

