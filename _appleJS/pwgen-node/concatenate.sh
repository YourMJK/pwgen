#!/bin/bash

cd $(dirname "$0")
cat ../js/*.js main.js > concatenated.js
