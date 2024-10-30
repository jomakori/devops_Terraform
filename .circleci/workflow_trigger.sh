set -e

WORKSPACES_raw="$(git diff -r --name-only master... | xargs dirname | sed 's:/.*::' | sed '/\./d'| sort | uniq)"
WORKSPACES=($WORKSPACES_raw) # convert to array

# Ignore WIP workspace changes
for value in "${!WORKSPACES[@]}"
do
    if [[ ${WORKSPACES[value]} == *"WIP"* ]]
    then
        unset 'WORKSPACES[value]'
    fi
done

# Confirming only one workspace is being committed & ran
echo Workspaces present: ${WORKSPACES[@]}
if (( ${#WORKSPACES[@]} == 1 )); then
    echo "Great - Only 1 workspace changed! Continuing workflow..."
    elif (( ${#WORKSPACES[@]} >= 2 )); then
    echo "Error: Too many workspaces edited."
    echo "Note: You can only add/change/remove one workpace for each PR."
    exit 1
else
    echo "No Terraform changes - ${#WORKSPACES[@]} workspaces have been changed."
fi

# Determine workflow based on changes
if [ -d ~/project/${WORKSPACES[0]} ]; then
    echo "${WORKSPACES[@]} Workspace - deploy-infras workflow will be triggered."
    cp $PWD/deploy-infras.yml $PWD/continue-config.yml
    elif [ ! -d ~/project${WORKSPACES[0]} ]; then
    echo "${WORKSPACES[@]} workspace no longer exists - destroy-infras workflow will be triggered."
    cp $PWD/destroy-infras.yml $PWD/continue-config.yml
else
    echo "ERROR: Variable condition is outside the scope."
    exit 1
fi

echo "Show Directory after changes:"
ls -a