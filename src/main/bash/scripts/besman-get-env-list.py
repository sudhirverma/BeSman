import requests
import os
import json
import sys
from besman_python_helper import ConstructURL

# Get environment variables


# if not env_repo:
#     print("check")
#     print("BESMAN_ENV_REPO var is not set")
#     sys.exit(1)
# elif local_env is True and not local_env_dir:
#     print("BESMAN_LOCAL_ENV_DIR var is not set")
#     sys.exit(1)


# Construct the URL
def get_env_list():

    env_repo = os.environ.get("BESMAN_ENV_REPO")
    branch = os.environ.get("BESMAN_ENV_REPO_BRANCH")
    besman_dir = os.environ.get("BESMAN_DIR")
    local_env = os.environ.get("BESMAN_LOCAL_ENV")
    local_env_dir = os.environ.get("BESMAN_LOCAL_ENV_DIR")
    # platform = os.environ.get("BESMAN_CODE_COLLAB_PLATFORM")
    # token = os.environ.get("BESMAN_ACCESS_TOKEN")
    file_path = 'environment-metadata.json'
    # Construct the URL
    url_constructor = ConstructURL(env_repo, branch, file_path)

    # Use the construct_raw_url method
    raw_url = url_constructor.construct_raw_url(env_repo, branch, file_path)
    
    # url = f'{raw_url}/environment-metadata.json'

    try:
        # Load data
        if local_env == "true":
            # Load local JSON file
            with open(os.path.join(local_env_dir, 'environment-metadata.json'), 'r') as local_file:
                data = json.load(local_file)
        else:
            # Fetch JSON from URL
            header = url_constructor.header_function()
            response = requests.get(raw_url, headers=header, timeout=10)
            response.raise_for_status()  # Raise an exception for bad responses (4xx or 5xx)
            data = response.json()
            # print(data)
        # Extract information
        extracted_info = []
        for environment in data['environments']:
            name = environment['name']
            author_name = environment['author']['name']
            version_tags = environment['version']['tag']

            # for tag in version_tags:
            extracted_info.append(f"{name} {author_name} {version_tags}")

        # Write the extracted information to a file
        output_file_path = os.path.join(besman_dir, "tmp", "environment_details.txt")
        os.makedirs(os.path.dirname(output_file_path), exist_ok=True)  # Ensure the directory exists
        with open(output_file_path, "w") as tmp_file:
            tmp_file.write("\n".join(extracted_info))

        sys.exit(0)  # Exit with a success code
    except requests.exceptions.RequestException as e:
        print(f"Error fetching data from url {raw_url}: {e}")
        sys.exit(1)  # Exit with an error code
    except (KeyError, TypeError, json.JSONDecodeError) as e:
        print(f"Error parsing JSON: {e}")
        sys.exit(2)  # Exit with an error code
    except IOError as e:
        print(f"Error writing to file: {e}")
        sys.exit(3)  # Exit with an error code
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        sys.exit(4)  # Exit with an error code

if __name__ == "__main__":

    get_env_list()
    