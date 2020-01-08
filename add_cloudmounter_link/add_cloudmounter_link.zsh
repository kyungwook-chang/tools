#!/usr/local/bin/zsh

#
# See how many drives are mounted.
#
md="$(ls -lh ~/.CMVolumes | wc -l | tr -d '[:space:]')";

if [[ $md = 0 ]]; then
	#
	# No drives are mounted. Remove their links.
	#
	# assign file descriptor 3 to input file
	exec 3< ~/.cmdrivesmounted;

	#
	# Remove each mount in the file.
	#
	until [ $done ]
	do
	    read <&3 file
	    if [ $? != 0 ]; then
	        done=1
	        continue
	    fi
		#
		# Remove the mounts.
		#
		rm "$file";
	done
	#
	# Clear out the list of mounted drives.
	#
	echo -n '' > ~/.cmdrivesmounted;
else
	#
	# assign file descriptor 3 to input file
	exec 3< ~/.cmdrivesmounted;

	#
	# Look for directories that have been unmounted.
	#
	echo '' > ~/.cmdrivesmounted2;
	until [ $done ]
	do
	    read <&3 file
	    if [ $? != 0 ]; then
	        done=1
	        continue
	    fi
	    bname=`basename "$file"`;
		if [[ ! -d "~/.CMVolumes/$file" ]]; then
			#
			# It isn't mounted anymore. Remove it.
			#
			rm "$file";
		else
			#
			# It's still there, add it back.
			#
			echo "$file" >> ~/.cmdrivesmounted2;
		fi
	done

	#
	# Remove the original and move the tmp to
	# the original location.
	#
	rm ~/.cmdrivesmounted;
	mv ~/.cmdrivesmounted2 ~/.cmdrivesmounted;

	#
	# Loop over the mounts from Cloud Mounter and see
	# which ones are new.
	#
	for file in ~/.CMVolumes/*; do
		bname=`basename "$file"`;
		#
		# See if the mount point has been linked yet.
		#
		if [[ ! -L "$/Volumes/$bname" ]]; then
			#
			# Create the mount point.
			#
			ln -s "$file" "/Volumes/$bname" &>/dev/null;

			#
			# Add to the list of mounted drives.
			#
			echo "/Volumes/$bname" >> ~/.cmdrivesmounted;
		fi
	done
fi
exit 0;
