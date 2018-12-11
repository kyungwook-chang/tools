#!/bin/bash

if [ "$#" -ne 2 ]; then
	echo "$0 old_directory new_directory"
	exit 0
fi
old_dir=$1
target_dir=$2

for link in `find . -lname "${old_dir}*"`; do
	echo $link
	target_link=$(readlink -- "$link")
	target_link=${target_link/$old_dir/$target_dir}

	echo ln -sfn -- "$target_link" "$link"
	ln -sfn "$target_link" "$link"
done
