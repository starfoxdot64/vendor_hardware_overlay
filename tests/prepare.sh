#!/bin/bash

# Check if an input file was provided
if [ $# -ne 1 ]; then
  echo ""
  echo ""
  echo "Error: Input XML not provided."
  echo ""
  echo "Usage: $0 inputFile.xml"
  echo ""
  echo "Keep in mind, this script will overwrite your input file. Make a backup!"
  exit 1
fi

input_file="$1"

# Check if the input file exists
if [ ! -f "$input_file" ]; then
  echo "Error: Input XML $input_file not found. Double-check your filename."
  exit 2
fi

# Read the lines in knownKeys into an array
readarray -t known_keys < knownKeys

# Create a temporary file to store the updated XML
temp_file=$(mktemp)

# Write an XML header and a resources tag to the temporary file
echo "<?xml version='1.0' encoding='utf-8'?>" > "$temp_file"
echo "<resources>" >> "$temp_file"

# Create a string to hold the XPath expression
xpath_expression="//*[@name='${known_keys[0]}'"

# Loop over each line in the known_keys array (starting from the second element)
for key in "${known_keys[@]:1}"; do
  # Add the current key to the XPath expression
  xpath_expression="$xpath_expression or @name='$key'"
done

# Close the XPath expression
xpath_expression="$xpath_expression]"

# Use xmllint to select nodes that match the XPath expression
xmllint --xpath "$xpath_expression" "$input_file" >> "$temp_file"

# Add the closing resources tag to the temporary file
echo "</resources>" >> "$temp_file"

# Replace the input XML file with the temporary file
mv "$temp_file" "$input_file"

# Inform user of success
echo ""
echo "Done editing $input_file."
echo ""
echo "Caution: Please be aware that this script may make errors - Check the results before you build, and be sure to use tests.sh to ensure nothing was missed."
