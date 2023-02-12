#!/bin/bash

# Check if xmllint is available, and offer minor help if it is not
if ! command -v xmllint &> /dev/null
then
    echo ""
    echo ""
    echo "We couldn't find the xmllint command on your system."
    echo "Without that, we can't parse XML files. Install the"
    echo "libxml2-utils package, then try again."
    echo ""
    echo ""
    exit 1
fi


# Check for an input file
if [ $# -ne 1 ]; then
  echo ""
  echo ""
  echo "Error: Input XML not provided."
  echo ""
  echo "Usage: $0 path/to/inputFile.xml"
  echo ""
  echo "Keep in mind, this script is experimental, and will"
  echo "overwrite your input file. If you haven't already,"
  echo "make a backup!"
  echo ""
  echo ""
  exit 2
fi

input_file="$1"

# Check if the input file exists
if [ ! -f "$input_file" ]; then
  echo ""
  echo ""
  echo "Error: Input XML $input_file not found. Double-check your filename."
  echo ""
  echo ""
  exit 3
fi

# Read the lines in knownKeys into an array
readarray -t known_keys < knownKeys

# Create a temporary file to store the updated XML
temp_file=$(mktemp)

# Write an XML header and a resources tag to the temporary file
echo "<?xml version='1.0' encoding='utf-8'?>" > "$temp_file"
echo "<resources>" >> "$temp_file"

# Create a string to hold an XPath expression to search with
xpath_expression="//*[@name='${known_keys[0]}'"

# Loop over each line in the known_keys array (starting from the second element)
for key in "${known_keys[@]:1}"; do
  # Add the current key to the XPath expression
  xpath_expression="$xpath_expression or @name='$key'"
done

# Close the XPath expression
xpath_expression="$xpath_expression]"

# Use xmllint to select nodes that match our criteria
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
