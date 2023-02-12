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

# Check if xmlstarlet is available, and offer minor help if it is not
if ! command -v xmlstarlet &> /dev/null
then
    echo ""
    echo ""
    echo "We couldn't find the xmlstarlet command on your system."
    echo "Without that, we can't parse XML files. Install the"
    echo "xmlstarlet package, then try again."
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

# Read the blacklist into an array
readarray -t blacklist < blacklist

# Create a temporary file to store the updated XML
temp_file=$(mktemp)

# Create a string to hold an XPath expression to search with,
# then Loop over each line in the known_keys array (starting from the second element)
xpath_expression_known="//*[@name='${known_keys[0]}'"
for key in "${known_keys[@]:1}"; do
  # Add the current key to the XPath expression
  xpath_expression_known="$xpath_expression_known or @name='$key'"
done
xpath_expression_known="$xpath_expression_known]"

# Write an XML header and a resources tag to the temporary file, since xmllint gets rid of it later
# Reminder to self: > will clear the file, >> appends to it
echo "<?xml version='1.0' encoding='utf-8'?>" > "$temp_file"
echo "<resources>" >> "$temp_file"

# Select nodes that match our known keys and put them in the tempfile
xmllint --xpath "$xpath_expression_known" "$input_file" >> "$temp_file"

# Create another xpath expression to carry blacklisted keys, doing the same as with the known keys
xpath_expression_blacklist="//*[@name='${blacklist[0]}'"
for key in "${blacklist[@]:1}"; do
  xpath_expression_blacklist="$xpath_expression_blacklist or @name='$key'"
done
xpath_expression_blacklist="$xpath_expression_blacklist]"

# Add closing tag, because xmllint doesn't carry it over
echo "</resources>" >> "$temp_file"

# Use xmlstarlet to select nodes we don't want, remove them, and put them in a new tempfile
xmlstarlet ed --delete "$xpath_expression_blacklist" "$temp_file" > "$temp_file-2"

# Swap out the input file after final edits, then clean up the last tempfile
mv "$temp_file-2" "$input_file"
rm "$temp_file"

# Inform user of success
echo ""
echo ""
echo "Done editing $input_file."
echo ""
echo "Caution: Please be aware that this script may make"
echo "errors - Check the results before you build, and be"
echo "sure to use tests.sh to ensure nothing was missed."
echo ""
echo "This script should be able to find blacklisted keys"
echo "and take care of them automatically, but there could"
echo "still have a few keys in the XML that will require"
echo "manual removals. It's better than dozens though!"
echo ""
echo ""