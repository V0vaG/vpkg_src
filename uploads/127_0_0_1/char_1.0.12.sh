#!/bin/bash

version='1.0.12'
#alias="${0%%_*}" 
alias="char"

if [[ $1 == '-v' ]]; then
	echo $version
	exit
elif [[ $1 == '-h' ]]; then
	help
	exit
fi

    # Get the directory from the first command-line argument, default to current directory if none provided
    DIR="${1:-.}"

    # Check if the provided argument is a directory
    if [ ! -d "$DIR" ]; then
        echo "Error: $DIR is not a directory."
        exit 1
    fi

    # Read user input for characters to replace
    read -p "Enter old char (default ' '): " old_char
    if [[ ! $old_char ]]; then
        old_char=' '
    fi

    read -p "Enter new char (default '_'): " new_char
    if [[ ! $new_char ]]; then
        new_char='_'
    fi

    # Function to rename directories (deepest first)
    rename_dirs() {
        local base_dir="$1"
        
        # Find and list directories with spaces
        find "$base_dir" -depth -type d -name "*$old_char*" | sort -r > directories.txt
        
        # Process the directories
        while IFS= read -r dir; do
            local new_dir=$(echo "$dir" | sed "s/$old_char/$new_char/g")
            if [ "$dir" != "$new_dir" ]; then
                echo "Renaming directory '$dir' to '$new_dir'"
                mv "$dir" "$new_dir"
            fi
        done < directories.txt
    }

    # Function to rename files
    rename_files() {
        local base_dir="$1"
        
        # Find and list files with spaces
        find "$base_dir" -type f -name "*$old_char*" > files.txt
        
        # Process the files
        while IFS= read -r file; do
            local new_file=$(echo "$file" | sed "s/$old_char/$new_char/g")
            if [ "$file" != "$new_file" ]; then
                echo "Renaming file '$file' to '$new_file'"
                mv "$file" "$new_file"
            fi
        done < files.txt
    }

    # Loop until no more files or directories need renaming
    while true; do
        # Rename directories
        rename_dirs "$DIR"

        # Rename files
        rename_files "$DIR"

        # Check if there are any remaining directories or files with spaces
        remaining_dirs=$(find "$DIR" -depth -type d -name "*$old_char*" | wc -l)
        remaining_files=$(find "$DIR" -type f -name "*$old_char*" | wc -l)

        if [ "$remaining_dirs" -eq 0 ] && [ "$remaining_files" -eq 0 ]; then
            break
        fi
        
        # Small delay to prevent rapid looping
        sleep 1
    done

    echo "Renaming complete."



