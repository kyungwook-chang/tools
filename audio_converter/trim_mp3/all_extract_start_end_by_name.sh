#!/bin/csh -f

# filename: AA_BB_23_1.34.mp3
# extract from 23sec to 1min 34sec
foreach tmp (`find . -name "*mp3" | sed 's/ /@@@@/g'`)
	set file=`echo $tmp | sed 's/@@@@/ /g'`
	set start_time=`echo $file | sed 's/.*_\([0-9][0-9]*\)_[0-9][0-9]*\.[0-9][0-9]*\.mp3/\1/g'`
	set end_min=`echo $file | sed 's/.*_[0-9][0-9]*_\([0-9][0-9]*\)\.[0-9][0-9]*\.mp3/\1/g'`
	set end_sec=`echo $file | sed 's/.*_[0-9][0-9]*_[0-9][0-9]*\.\([0-9][0-9]*\)\.mp3/\1/g'`
	set end_time=`perl -e "print $end_min*60+$end_sec"`
	~/Scripts/trim_mp3/extract_start_end.sh "$file" $start_time $end_time
end
