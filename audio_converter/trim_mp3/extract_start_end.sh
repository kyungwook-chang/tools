#!/bin/csh -f 

set input_filename="$1"
set basename=`echo $input_filename:r`
set extname=`echo $input_filename:e`
echo $basename
echo $extname
set output_filename="${basename}_cut.$extname"

set start_time="$2"
set end_time="$3"

set duration=`perl -e "print $end_time - $start_time"`
echo $duration

ffmpeg -ss $start_time -t $duration -i "$input_filename" -acodec copy "$output_filename"
