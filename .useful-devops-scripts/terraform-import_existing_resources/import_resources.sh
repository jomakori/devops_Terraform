#!/bin/bash
set +o posix

main() {
printf $blue"Logging Beginning...\n"$normal

# Declarations
csv_file="../.useful-devops-scripts/terraform-import_existing_resources/import_resources.csv"
counter=1

blue="\e[94m"
yellow="\e[33m"
normal="\e[0m"

# Prompt
printf "What's the name of the resource you're wishing to import? "
echo ""
read resource_name

# Loop command w/ variables
while IFS="," read -r csv_column1 csv_column2
do
    printf $yellow"Line $counter"$normal
    echo ""
    echo "terraform import $resource_name["$csv_column1"] $csv_column2"
    doppler run --command='terraform import $resource_name["$csv_column1"] $csv_column2'
    echo ""
    let counter++
done < <(tail -n +2 $csv_file)

# Finish logging  Log output from command
printf $blue"Logging Finished. Log script saved in $(pwd)/session.log"$normal
}

main | tee session.ansi # Outputs log file w/ color codes
