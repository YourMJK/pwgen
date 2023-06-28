#!/bin/bash

cd $(dirname "$0")
cat apple/* main.js | sed 's|window\.crypto|crypto|g' > compiled.js
