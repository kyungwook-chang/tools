#!/bin/bash

for f in *.ogg; do
	ffmpeg -i "$f" -acodec libmp3lame -ab 128k "${f%.ogg}.mp3"
done
