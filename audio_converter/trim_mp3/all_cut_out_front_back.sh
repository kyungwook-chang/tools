#!/bin/csh -f

set front_cut_amount = $1
set back_cut_amount = $2

find . -name "*mp3" -exec ~/Scripts/trim_mp3/cut_out_front_back.sh "{}" $front_cut_amount $back_cut_amount \;
