#!/bin/bash

# Check if argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <path_to_accounts.csv>"
    exit 1
fi

# Read input file path
input_file=$1

# Check if input file exists
if [ ! -f "$input_file" ]; then
    echo "Input file '$input_file' not found."
    exit 1
fi

# Function to update name format
update_name() {
    local name="$1"    
    # Name format: first letter of name/surname uppercase and all other letters lowercase.
    echo "$name" | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1'
}

# Function to update email format
update_email() {
    local name="$1"
    local surname="$2"
    local location_id="$3"
    local domain="@abc.com"
    # Email format: first letter from name and full surname, lowercase.    
    local email="$(echo "${name:0:1}${surname,,}" | tr '[:upper:]' '[:lower:]')"
    # If location_id is provided, append it to the email
    if [ -n "$location_id" ]; then
        email="${email}${location_id}"
    fi
    # Need to update column email with domain @abc.
    email="${email}${domain}"
    echo "$email"
}

# Function to count occurrences of a specific lowercase string in an array
# param $1 the element, param $2 is the array
count_item() {
    local item="$(echo "$1" | tr '[:upper:]' '[:lower:]' )"             # the searched element in lowercase
    local item="${item:0:1}${item#* }"                                  # create the email alias: first letter of the firstname and the surname in lowercase
    local inputs=("$@")                                                 # Copy input array
    local array=("${inputs[@]:1}")                                      # Extract elements from the 2nd to the last element
    local count=0                                                       # Initialize count
    email=$(update_email "${lwcname:0:1}" "${lwcname#* }" "$location")

    # Iterate over the array and count occurrences of the item
    for element in "${array[@]}"; do
        element=$(echo "$element" | tr '[:upper:]' '[:lower:]')         # the iterated item in lowercase
        element="${element:0:1}${element#* }"                           # create the email alias: first letter of the firstname and the surname in lowercase
        if [ "$element" = "$item" ]; then
            ((count++))
        fi
    done

    echo "$count"    
}

# Process each line of the $input_file file from the 2nd line into arrays
while IFS=',' read -ra array; do
    arr_ids+=("${array[0]}")
    arr_locations+=("${array[1]}")
    arr_names+=("${array[2]}")
    arr_titles+=("${array[3]}")
    arr_emails+=("${array[4]}")
    arr_departments+=("${array[5]}")
done < <(tail -n +2 "$input_file")

# Header of the output .csv
echo "id,location_id,name,title,email,department" > accounts_new.csv
#iterate through the arrays and generate the outputfile
i=0
for name in "${arr_names[@]}"; do
    #craft the ID column 
    user_id=${arr_ids[$i]}

    #craft the location column 
    location=${arr_locations[$i]}
    
    # Update name format and create the name column
    updated_name=$(update_name "$name")

    #craft the position column 
    position=${arr_titles[$i]}

    # Full name in lowercase format
    lwcname=$(echo "$name" | tr '[:upper:]' '[:lower:]')
    
    #Check if the name presented in the list if yes: Equals emails should contain location_id.
    count=$(count_item "$name" "${arr_names[@]}")
    if [[ $count -gt 2 ]] ; then        
        # updated_email=$(update_email "${name:0:1}" "${name#* }" "$location_id")
        location="$location$user_id"        
        email=$(update_email "${lwcname:0:1}" "${lwcname#* }" "$location")
    elif [[ $count -eq 2 ]]; then
        email=$(update_email "${lwcname:0:1}" "${lwcname#* }" "$location")
    else
        email=$(update_email "${lwcname:0:1}" "${lwcname#* }")
    fi

    #craft the department column 
    department=${arr_departments[$i]}

    # Output updated line to new CSV
    echo "$user_id,$location,$updated_name,$position,$email,$department,"

    ((i+=1))

done >> accounts_new.csv        # Appened the result to the accounts_new.csv file

echo "Script finished"          # Srcipt finished