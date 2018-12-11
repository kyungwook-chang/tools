#!/bin/csh -f 

set input_filename="$1"
set basename=`echo $input_filename:r`
set extname=`echo $input_filename:e`
echo $basename
echo $extname
set output_filename="${basename}_cut.$extname"

set front_cut_amount="$2"
set back_cut_amount="$3"

set duration_org=`ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$input_filename"`
set duration_mod=`perl -e "print $duration_org - $front_cut_amount - $back_cut_amount"`
echo $duration_org
echo $duration_mod

ffmpeg -ss $front_cut_amount -t $duration_mod -i "$input_filename" -acodec copy "$output_filename"
