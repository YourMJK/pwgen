#!/bin/bash

dest=$(dirname "$0")
baseURL="https://developer.apple.com/password-rules/scripts"
scripts=(
	"parser.js"
	"safariQuirkBuilder.js"
	"generator.js"
#	"password-rules.js"
)

for script in "${scripts[@]}"
do
	file="$dest"/"$script"
	wget -nv -O "$file" "$baseURL"/"$script"
	sed -i '' 's|window\.crypto|crypto|g' "$file"
done
