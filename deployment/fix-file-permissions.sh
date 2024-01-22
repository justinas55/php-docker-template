#!/bin/bash

echo "If you are getting access denied errors when app is dealing with files or it's not working at all - there may be a problem with file permissions"
echo "This script assumes that you are working with one user and that user owns the whole app folder recursively."
echo "If this is what you want - proceed - it may likely fix it automatically, otherwise - better fix manually - this script may do more harm than good."
echo "Steps:"
echo "1) Check file ownership of current directory recursively and verify it matches current user"
echo "2) If all files have correct ownership - report success and exit. Else continue."
echo "3) Ask user confirmation to run 'chown -R $(id -u):$(id -g) .' - this will replace ownership of current directory and all its files recursively to current user/group"

# Get the current user's ID and group ID
current_user_id=$(id -u)
current_group_id=$(id -g)

# Function to check file ownership
check_ownership() {
    # Find files not owned by current user
    incorrect_files=$(find . ! -user $current_user_id -o ! -group $current_group_id)

    if [ -z "$incorrect_files" ]; then
        echo "Success: All files in the current directory and subdirectories are owned by the current user."
        exit 0
    else
        echo "Warning: Some files are not owned by the current user. Ownership needs to be changed."
        echo "Files with incorrect ownership:"
        echo "$incorrect_files"
    fi
}

# Function to change file ownership
change_ownership() {
    chown_output=$(chown -R $current_user_id:$current_group_id . 2>&1)
    chown_status=$?

    if [ $chown_status -ne 0 ]; then
        echo "$chown_output"
        if [[ $chown_output == *"denied"* || $chown_output == *"not permitted"* ]]; then
            read -p "Access denied or operation not permitted. Do you want to try running the command with sudo? (y/n): " sudo_confirmation
            if [ "$sudo_confirmation" = "y" ]; then
                sudo chown -R $current_user_id:$current_group_id .
                echo "Ownership has been changed to the current user/group for all files in the current directory and subdirectories with sudo."
            else
                echo "Operation cancelled by the user."
                exit 1
            fi
        fi
    else
        echo "Ownership has been changed to the current user/group for all files in the current directory and subdirectories."
    fi
}

# Check file ownership
check_ownership

# Confirm with the user before changing ownership
read -p "Do you want to change the ownership of all files in the current directory and its subdirectories to the current user/group? (y/n): " confirmation
if [ "$confirmation" = "y" ]; then
    # Change ownership
    change_ownership
else
    echo "Operation cancelled by the user."
    exit 1
fi
