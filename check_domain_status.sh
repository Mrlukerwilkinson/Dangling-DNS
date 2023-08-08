#!/bin/bash

# Populate a txt file of domains you want to check - each domain should be on a separate line
input_file="domain_list.txt"

# Location of where the output file should be saved
output_file="dns_results.csv"

# Create or truncate the CSV file
echo "Domain,Status" > "$output_file"

# Read domains from input file
while IFS= read -r domain || [[ -n "$domain" ]]; do
    result=$(dig "$domain")
    status_line=$(echo "$result" | grep -E "status: [A-Z]+" | tail -1)
    
    if [[ "$status_line" == *"NXDOMAIN"* ]]; then
        status="NXDOMAIN"
    elif [[ "$status_line" == *"NOERROR"* ]]; then
        status="NOERROR"
    elif [[ "$status_line" == *"SERVFAIL"* ]]; then
        status="SERVFAIL"
    elif [[ "$status_line" == *"REFUSED"* ]]; then
        status="REFUSED"
    else
    # Add additional status codes if necessary
        status="Unknown status"
    fi

    # Append the result to the CSV file
    echo "$domain,$status" >> "$output_file"
    
    # Display the result on the screen
    echo "$domain: $status"
done < "$input_file"
