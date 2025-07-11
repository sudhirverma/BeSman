#!/bin/bash

function __bes_list {

    local flag=$1
    local env sorted_list

    __besman_check_for_access_token
    # For listing playbooks
    if [[ (-n $flag) && (($flag == "--playbook") || ($flag == "-P")) ]]; then

        __besman_list_playbooks

    elif [[ (-n $flag) && ($flag == "--role") ]]; then

        __besman_list_roles
    elif [[ (-n $flag) && (($flag == "--environment") || ($flag == "-env")) ]]; then

        __besman_list_envs

    else

        __besman_echo_white "---------------------------ENVIRONMENTS-----------------------------------------------"
        __besman_echo_no_colour ""
        __besman_list_envs
        __besman_echo_no_colour ""
        __besman_echo_white "---------------------------PLAYBOOKS--------------------------------------------------"
        __besman_echo_no_colour ""
        __besman_list_playbooks
        __besman_echo_no_colour ""
        __besman_echo_white "---------------------------ROLES------------------------------------------------------"
        __besman_echo_no_colour ""
        __besman_list_roles
        __besman_echo_no_colour ""
    fi
}
function __besman_list_envs() {
    local current_version current_env installed_annotation remote_annotation local_list

    local_list="$BESMAN_DIR/var/list.txt"

    __besman_check_repo_exist || return 1
    __besman_update_list || return 1
    # __besman_echo_no_colour "Github Org    Repo                             Environment     Version"
    # __besman_echo_no_colour "-----------------------------------------------------------------------------------"

    [[ -f "$BESMAN_DIR/var/current" ]] && current_env=$(cat "$BESMAN_DIR/var/current")
    [[ -f "$BESMAN_DIR/envs/besman-$current_env/current" ]] && current_version=$(cat "$BESMAN_DIR/envs/besman-$current_env/current")

    installed_annotation=$(__besman_echo_yellow "*")
    remote_annotation=$(__besman_echo_yellow "^")

    # For listing environments
    printf "%-25s %15s %15s\n" "Environment" "Author" "Version"
    __besman_echo_no_colour "-----------------------------------------------------------"

    [[ -f "$BESMAN_DIR/tmp/environment_details.txt" ]] && cp "$BESMAN_DIR/tmp/environment_details.txt" "$local_list" && rm "$BESMAN_DIR/tmp/environment_details.txt"

    sed -i '/^$/d' "$local_list"
    sorted_list=$(sort "$local_list")
    echo "$sorted_list" >"$local_list"
    OLD_IFS=$IFS
    IFS=" "

    while read -r line; do
        # converted_line=$(echo "$line" | sed 's|,|/|g')
        read -r env author version <<<"$line"

        # echo "line=$line"
        if [[ ("$env" == "$current_env") && ("$version" == "$current_version") ]]; then
            printf "%-25s %15s %25s\n" "$env" "$author" "$version$installed_annotation"
        else
            printf "%-25s %15s %25s\n" "$env" "$author" "$version$remote_annotation"

        fi

    done <"$local_list"
    IFS=$OLD_IFS

    __besman_echo_no_colour ""

    __besman_echo_no_colour "==================================================================================="
    __besman_echo_no_colour "$remote_annotation - remote environment"
    __besman_echo_no_colour "$installed_annotation - installed environment"
    __besman_echo_no_colour "==================================================================================="
    __besman_echo_no_colour ""

    unset flag arr env list

    if [[ $BESMAN_LOCAL_ENV == "true" ]]; then

        __besman_echo_white "Listing from local dir $(__besman_echo_yellow "$BESMAN_LOCAL_ENV_DIR")"
        __besman_echo_no_colour ""
        __besman_echo_white "If you wish to list from remote repo, run the below command"
        __besman_echo_yellow "$ bes set BESMAN_LOCAL_ENV false"
        __besman_echo_yellow "$ bes set BESMAN_ENV_REPO <GitHub Org>/<Repo name>"
    else
        __besman_echo_white "Listing from $(__besman_echo_yellow "$BESMAN_ENV_REPO"); branch - $(__besman_echo_yellow "$BESMAN_ENV_REPO_BRANCH")"
        __besman_echo_no_colour ""
        __besman_echo_white "If you wish to change the repo, run the below command"
        __besman_echo_yellow "$ bes set BESMAN_ENV_REPO <GitHub Org>/<Repo name>"
        __besman_echo_no_colour ""
        __besman_echo_white "If you wish to change the branch, run the below command"
        __besman_echo_yellow "$ bes set BESMAN_ENV_REPO_BRANCH <branch>/<tag>"
    fi
}



function __besman_check_repo_exist() {
    local namespace repo response repo_url
    [[ $BESMAN_LOCAL_ENV == "true" ]] && return 0
    # namespace=$(echo "$BESMAN_ENV_REPO" | cut -d "/" -f 1)
    # repo=$(echo "$BESMAN_ENV_REPO" | cut -d "/" -f 2)

    repo_url=$(__besman_construct_repo_url "$BESMAN_ENV_REPO")

   __besman_check_url_valid "$repo_url" || return 1

    # if [[ -n "$response" && "$response" -ne 200 ]]; then
    #     __besman_echo_error "Repository $repo does not exist under $namespace"
    #     return 1
    # fi

}

function __besman_update_list() {
    local bes_list exit_code
    local env_script_file="$BESMAN_DIR/scripts/besman-get-env-list.py"

    [[ ! -f $env_script_file ]] && __besman_echo_error "Could not find script file for env listing: $env_script_file" && return 1

    if [[ (-n $BESMAN_LOCAL_ENV) && ($BESMAN_LOCAL_ENV == "true") ]]; then
        local env_dir_list bes_list
        if [[ -z $BESMAN_LOCAL_ENV_DIR ]]; then
            __besman_echo_error "Could not find your local environment dir"
            __besman_echo_no_colour ""
            __besman_echo_white "Use the below command to set it first"
            __besman_echo_no_colour ""
            __besman_echo_yellow "$ bes set BESMAN_LOCAL_ENV_DIR <complete path to your local env dir>"
            __besman_echo_no_colour ""

            return 1
        fi
        [[ ! -d $BESMAN_LOCAL_ENV_DIR ]] && __besman_echo_error "Could not find dir $BESMAN_LOCAL_ENV_DIR" && return 1
        # local env_script_file="$BESMAN_DIR/scripts/besman-get-env-list.py"
        python3 $env_script_file
        # env_dir_list=$(< "$BESMAN_LOCAL_ENV_DIR/list.txt")
        # bes_list=$BESMAN_DIR/var/list.txt
        # echo "$env_dir_list" > "$bes_list"
    else

        # local org repo path
        # org=$(echo "$BESMAN_ENV_REPO" | cut -d "/" -f 1)
        # repo=$(echo "$BESMAN_ENV_REPO" | cut -d "/" -f 2)
        # branch=$BESMAN_ENV_REPO_BRANCH
        # bes_list="$BESMAN_DIR/var/list.txt"
        # # path="https://raw.githubusercontent.com/$org/$repo/$branch/list.txt"
        # # __besman_secure_curl "$path" > "$bes_list"
        # local env_script_file="$BESMAN_DIR/scripts/besman-get-env-list.py"

        python3 $env_script_file

        exit_code=$?

        if [[ $exit_code -eq 0 ]]; then
            return 0
        elif [[ $exit_code -eq 1 ]]; then
            __besman_echo_error "Error fetching data."
            return 1
        elif [[ $exit_code -eq 2 ]]; then
            __besman_echo_error "Error parsing JSON."
            return 1
        elif [[ $exit_code -eq 3 ]]; then
            __besman_echo_error "Error writing to file."
            return 1
        else
            __besman_echo_error "An unexpected error occurred."
            return 1
        fi
    fi

}

# Function to extract repository names from a JSON response
function __besman_extract_repo_names() {
    echo "$1" | grep -oP '"full_name": "\K[^"]+'
}

function __besman_list_roles() {
    local api_url repo_names all_repo_names page_num ansible_roles

    if [[ -z "$BESMAN_GH_TOKEN" ]]; then
        __besman_echo_yellow "Github token missing. Please use the below command to export the token"
        __besman_echo_no_colour ""
        __besman_echo_no_colour "$ bes set BESMAN_GH_TOKEN <copied token>"
        __besman_echo_no_colour ""
        return 1
    fi

    api_url="https://api.github.com/orgs/$BESMAN_NAMESPACE/repos?per_page=100&page=1"

    # Get the first page of repository names
    repo_names=$(curl -s -H "Authorization: token $BESMAN_GH_TOKEN" "$api_url")

    # Extract repository names from the first page
    all_repo_names=$(__besman_extract_repo_names "$repo_names")
    page_num=1
    # Check if there are more pages and continue fetching if needed
    while [ "$(echo "$repo_names" | grep -c '"full_name"')" -eq 100 ]; do
        page_num=$((page_num + 1))
        api_url="https://api.github.com/orgs/$BESMAN_NAMESPACE/repos?per_page=100&page=$page_num"
        repo_names=$(curl -s -H "Authorization: token $BESMAN_GH_TOKEN" "$api_url")
        all_repo_names="$all_repo_names
        $(__besman_extract_repo_names "$repo_names")"
    done

    ansible_roles=$(echo "$all_repo_names" | grep "ansible-role-*")

    printf "%-14s %10s \n" "Github Org" "Repo"
    __besman_echo_no_colour "-----------------------------------"
    for i in $ansible_roles; do
        converted_i=$(echo "$i" | sed "s|/| |g")
        read -r org repo <<<"$converted_i"
        printf "%-14s %-32s \n" "$org" "$repo"
    done

}

function __besman_get_playbook_details() {
    local scripts_file
    local environment=$1
    local version=$2
    scripts_file="$BESMAN_DIR/scripts/besman-get-playbook-details.py"

    [[ ! -f "$scripts_file" ]] && __besman_echo_error "Could not find $scripts_file" && return 1

    if [[ -z $environment || -z $version ]]; then
        python3 "$scripts_file" --master_list True
    else
        python3 "$scripts_file" --environment "$environment" --version "$version"
    fi

    if [[ "$?" != "0" ]]; then
        __besman_echo_error "Error while fetching playbook details"
        return 1
    fi
}
function __besman_list_playbooks() {

    local playbook_details_file playbook_details local_annotation remote_annotation

    [[ ! -f "$BESMAN_DIR/var/current" || -z $(cat "$BESMAN_DIR/var/current") ]] && __besman_echo_error "Missing environment" && __besman_echo_white "\nInstall an environment to get the list of compatible playbooks" && return 1

    local current_env=$(cat "$BESMAN_DIR/var/current")

    [[ -z $current_env ]] && __besman_echo_error "Could not find installed environment" && return 1

    [[ ! -d "$BESMAN_DIR/envs/besman-$current_env" ]] && __besman_echo_error "Could not find installed environment" && return 1

    local current_env_version=$(cat "$BESMAN_DIR/envs/besman-$current_env/current")

    playbook_details_file="$BESMAN_DIR/tmp/playbook_details.txt"

    __besman_get_playbook_details "$current_env" "$current_env_version" || return 1
    [[ ! -f "$playbook_details_file" ]] && __besman_echo_error "Could not find playbook details file" && return 1
    playbook_details=$(cat "$playbook_details_file")

    [[ (! -f "$playbook_details_file") || (-z $playbook_details) ]] && __besman_echo_error "Could not find playbook details" && return 1

    local_annotation=$(__besman_echo_yellow "+")
    remote_annotation=$(__besman_echo_yellow "^")
    printf "\n%-35s Compatible playbooks for $(__besman_echo_yellow "$current_env" "$current_env_version")"
    __besman_echo_white "\n=======================================================================================================================\n"
    printf "\e[1m%-35s %-25s %-8s %-8s %-23s %-30s\e[0m\n" "PLAYBOOK NAME" "INTENT" "VERSION" "TYPE" "AUTHOR" "DESCRIPTION"
    __besman_echo_no_colour "-------------------------------------------------------------------------------------------------------------------------------------"

    OLD_IFS=$IFS
    IFS=" "

    while read -r line; do
        # converted_line=$(echo "$line" | sed 's|,|/|g')
        read -r name intent version type author description <<<"$line"
        # Do not remove space. Used for indentation of description
        wrapped_desc=$(echo "$description" | fold -w 40 -s | sed '2,$s/^/                                                                                             /')
        if [[ -f "$BESMAN_PLAYBOOK_DIR/besman-$name-$version-playbook.sh" ]]; then

            printf "%-35s %-25s %-8s %-8s %-23s %-30s\n\n" "$name" "$intent" "$version" "$type" "$author$local_annotation" "$wrapped_desc"
        else
            printf "%-35s %-25s %-8s %-8s %-23s %-30s\n\n" "$name" "$intent" "$version" "$type" "$author$remote_annotation" "$wrapped_desc"

        fi

    done <<<"$playbook_details"
    IFS=$OLD_IFS

    if [[ $BESMAN_LOCAL_PLAYBOOK == "false" ]]; then

        __besman_echo_no_colour ""
        __besman_echo_no_colour "======================================================================="
        __besman_echo_no_colour "$remote_annotation - remote playbook"
        __besman_echo_no_colour "$local_annotation - local playbook"
        __besman_echo_no_colour "======================================================================="
        __besman_echo_no_colour ""

        __besman_echo_no_colour ""
        __besman_echo_white "Listing from $(__besman_echo_yellow "$BESMAN_PLAYBOOK_REPO"); branch - $(__besman_echo_yellow "$BESMAN_PLAYBOOK_REPO_BRANCH")"
        __besman_echo_white "If you wish to change the repo run the below command"
        __besman_echo_yellow "$ bes set BESMAN_PLAYBOOK_REPO <GitHub Org>/<Repo name>"
        __besman_echo_no_colour ""
        __besman_echo_white "If you wish to change the branch run the below command"
        __besman_echo_yellow "$ bes set BESMAN_PLAYBOOK_REPO_BRANCH <branch>/<tag>"

        __besman_echo_white "If you wish to load from Local dir, execute below command"
        __besman_echo_yellow "$ bes set BESMAN_LOCAL_PLAYBOOK true"
        __besman_echo_yellow "$ bes set BESMAN_LOCAL_PLAYBOOK_DIR 'pass complete path to local playbook dir'"

        [[ -f $playbook_details_file ]] && rm "$playbook_details_file"
    else
        __besman_echo_white "\n"
        __besman_echo_no_colour ""
        __besman_echo_white "Listing from local playbook directory - $BESMAN_LOCAL_PLAYBOOK_DIR"
        __besman_echo_white "If you wish to load from Remote, execute below command"
        __besman_echo_yellow "$ bes set BESMAN_LOCAL_PLAYBOOK false"
    fi

}
