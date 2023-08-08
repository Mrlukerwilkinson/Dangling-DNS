#!/bin/bash

domains=("example.com" "google.com")
output_file="dns_results.csv"

# Create or truncate the CSV file
echo "Domain,Status" > "$output_file"

for domain in "${domains[@]}"; do
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
        status="Unknown status"
    fi

    # Append the result to the CSV file
    echo "$domain,$status" >> "$output_file"
    
    # Display the result on the screen
    echo "$domain: $status"
done
