#!/bin/bash

function __bes_set()
{
    local variable_name file_path new_value
    variable_name=$1
    new_value=$2
    file_path="$BESMAN_DIR/etc/user-config.cfg"

    if [[ ( -z $variable_name ) || (-z $new_value) ]]; then
        __bes_help_set
        return 1
    fi

    if [[ ! -f "$file_path" ]]; then
    __besman_echo_red "File not found: $file_path"
    return 1
    fi
    __besman_check_if_variable_exist "$variable_name" "$file_path" || return 1
    __besman_update_env_value "$variable_name" "$new_value"

}


function __besman_check_if_variable_exist()
{
    local variable_name file_path
    variable_name=$1
    file_path=$2
    if ! grep -q "$variable_name" "$file_path"
    then
        __besman_echo_red "Not a valid variable"
        return 1
    fi
}
function __besman_update_env_value()
{
    local variable_name new_value
    variable_name=$1
    new_value=$2
    if [[ $variable_name == "BESMAN_ENV_REPO" && $(echo "$new_value" | sed 's|/| |g' | wc -w) -eq 2 ]]; then
        sed -i "s|\($variable_name *= *\).*|\1$new_value|" "$file_path"
    elif [[ $variable_name == "BESMAN_ENV_REPO" && $(echo "$new_value" | sed 's|/| |g' | wc -w) -eq 1 ]]; then
        sed -i "s|\($variable_name *= *\).*|\1$new_value/besecure-ce-env-repo|" "$file_path"
    else
        sed -i "s|\($variable_name *= *\).*|\1$new_value|" "$file_path"
    fi
    source "$BESMAN_DIR/bin/besman-init.sh"
    __besman_echo_yellow "Variable '$variable_name' value updated to '$new_value'"

}
