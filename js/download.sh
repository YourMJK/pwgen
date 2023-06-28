#!/bin/bash

dest=$(dirname "$0")/apple
baseURL="https://developer.apple.com/password-rules/scripts"
scripts=(
	"parser.js"
	"safariQuirkBuilder.js"
	"generator.js"
#	"password-rules.js"
)

rm -v "$dest"/*
printf "$baseURL/%s\n" "${scripts[@]}" | wget -nv -i - -P "$dest"
