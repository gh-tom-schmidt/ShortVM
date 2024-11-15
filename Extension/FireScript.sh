#!/bin/bash

# read JSON input from stdin
 read input

# extract URL from the JSON message
 selected_text=$(echo "$input" | grep -oP '"text":\s*"\K[^"]+')

# run installation command with the URL
v -iw "$selected_text" "$(basename "$selected_text")"

# send a response (JSON format)
echo '{"status": "success"}'


