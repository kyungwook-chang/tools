#!/bin/bash

for f in *.m4a; do
	ffmpeg -i "$f" -acodec libmp3lame -ab 128k "${f%.m4a}.mp3"
done
