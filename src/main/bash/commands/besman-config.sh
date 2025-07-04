#!/bin/bash

function __bes_config()
{
    local environment_name version user_config bes_config

    environment_name=$1
    version=$2

    user_config="$BESMAN_DIR/etc/user-config.cfg"
    bes_config="$BESMAN_DIR/etc/config"

    if [[ -z $environment_name ]] 
    then
        __besman_echo_yellow "User did not pass environment parameters"
        __besman_echo_yellow ""
        __besman_echo_no_colour "Trying to open BeSman config files in vscode.."
        __besman_open_files_in_vscode "$user_config" "$bes_config"

    else
        if echo "$environment_name" | grep -qE 'RT|BT'; then
            ossp=$(echo "$environment_name" | sed -E 's/-(RT|BT)-env//')
        else
            ossp=$(echo "$environment_name" | cut -d "-" -f 1)

        fi
        config_file=besman-$environment_name-config.yaml
        raw_url=$(__besman_construct_raw_url "$BESMAN_ENV_REPO" "$BESMAN_ENV_REPO_BRANCH" "$ossp/$version/$config_file")
        
        if [[ -f $HOME/$config_file ]] 
        then
            __besman_prompt_user "$config_file"
            [[ "$?" != "0" ]] && return 1

        fi  
        [[ -f $HOME/$config_file ]] && rm "$HOME/$config_file"
        __besman_check_url_valid "$raw_url" || return 1
        __besman_echo_white "Downloading config file from $(__besman_echo_yellow "$BESMAN_ENV_REPO"); branch - $(__besman_echo_yellow "$BESMAN_ENV_REPO_BRANCH")"

        __besman_secure_curl "$raw_url" >> "$HOME/$config_file"

        __besman_echo_no_colour "Trying to open config file in vscode.."
        __besman_open_files_in_vscode "$HOME/$config_file"
    fi

}

# Prompts user to confirm whether to replace existing env config file
function __besman_prompt_user()
{
    local config_file=$1
    local prompt
    __besman_echo_yellow "File $config_file already exists under $HOME"

    while true; do
        read -rp "Do you wish to replace? (y/Y/n/N): " prompt
        case $prompt in
            [Yy]* )
                __besman_echo_yellow "Replacing..."
                # Add your replacement logic here
                return 0
                ;;
            [Nn]* )
                __besman_echo_yellow "You chose not to replace."
                __besman_echo_white "Exiting.."
                return 1
                ;;
            * )
                __besman_echo_red "Invalid input. Please enter 'y' or 'n'."
                ;;
        esac
    done
}


# For opening files in vscode if available; else ask user to open it manually
function __besman_open_files_in_vscode()
{
    local files=( "$@" )

    if [[ -z $(command -v code) ]] 
    then
        __besman_echo_yellow "VS code not found"

        __besman_echo_no_colour "Please open the below file(s) in your editor manually"

        for i in "${files[@]}"; 
        do
            __besman_echo_yellow "$i"
        done
    else
        
        code "${files[@]}"

    fi
}
