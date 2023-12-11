#!/bin/bash

# Create output directory if it doesn't exist
mkdir -p output

# Set the input file
input_file="domains.txt"

# Set the dictionary file
dictionary_file="dicionario-br-sem-acentos.txt"

# Set the targets file
targets_file="targets.txt"

# Get the number of domains in the input file
number_of_domains=$(wc -l < "$input_file")

# Save target targets in an array
targets=()
while IFS= read -r target; do
  targets+=("$target")
done < $targets_file

# Reorder the targets targets putting the longest first to avoid overlap errors
targets=($(printf '%s\n' "${targets[@]}" | awk '{ print length, $0 }' | sort -nr | cut -d" " -f2-))

# Remove the output files if they exist
echo "Removing output files if they exist"
rm -f output/*

echo "Processing $number_of_domains domains"
while IFS= read -r domain; do
  # Remove the TLD from the domain
  domain_without_tld="${domain%%.*}"

  # Check the length of the domain without TLD
  domain_length=${#domain_without_tld}

  # Organize the domains based on length
  case $domain_length in
    1|2|3)
      echo "$domain" >> output/3-_chars.txt
      ;;
    4)
      echo "$domain" >> output/4_chars.txt
      ;;
    5)
      echo "$domain" >> output/5_chars.txt
      ;;
    6)
      echo "$domain" >> output/6_chars.txt
      ;;
  esac

  # For each target in the targets Check if the domain contains it
  for target in "${targets[@]}"; do
    if [[ $domain_without_tld == *"$target"* ]]; then
      echo "$domain" >> output/$target.txt
      break
    fi
  done
  
  # Display the progress
  echo -ne "$((++i * 100 / number_of_domains))% done\r"

done < "$input_file"

cd output

# For each target output file reorder its contents putting the domains ending in .com.br first
echo "Reordering target-based files"
for file in $(ls | grep -v "_chars"); do
  sort -k 2 -t . "$file" > "$file.sorted"
  rm "$file"
  grep ".com.br" "$file.sorted" > "$file.sorted.com.br"
  grep -v ".com.br" "$file.sorted" > "$file.sorted.not.com.br"
  cat "$file.sorted.com.br" "$file.sorted.not.com.br" > "$file"
  rm "$file.sorted.com.br" "$file.sorted.not.com.br" "$file.sorted"
done

# For the files based on length, reorder them putting domains that match words in the dictionary first
echo "Reordering lenght-based files"
for file in $(ls | grep "_chars"); do
  sort -k 2 -t . "$file" > "$file.sorted"
  rm "$file"
  grep -f "../$dictionary_file" "$file.sorted" > "$file.sorted.dictionary"
  grep ".com.br" "$file.sorted.dictionary" > "$file.sorted.dictionary.com.br"
  grep -v ".com.br" "$file.sorted.dictionary" > "$file.sorted.dictionary.not.com.br"
  grep -v -f "../$dictionary_file" "$file.sorted" > "$file.sorted.not.dictionary"
  cat "$file.sorted.dictionary.com.br" "$file.sorted.dictionary.not.com.br" "$file.sorted.not.dictionary" > "$file"
  rm "$file.sorted.dictionary" "$file.sorted.not.dictionary" "$file.sorted.dictionary.com.br" "$file.sorted.dictionary.not.com.br" "$file.sorted"
done
