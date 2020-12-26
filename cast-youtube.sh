#!/bin/bash

#vf='bestvideo[vcodec=avc1.4d401f]'
#vf='bestvideo[container=mp4]'
vf=136/137/22
#af='bestaudio[acodec=mp4a.40.2]'
#af='bestaudio[container=m4a_dash]/bestaudio[container=mp4]'
af=251/bestaudio

self=$( which $0 )
tools=$( realpath "${self%/*}" )
url=$1
name=$( echo $url | sed -E -e 's/^.*\?v=([a-zA-Z0-9]*).*$/\1/' )

path="/var/www/html/dash"
dash="http://192.168.31.152/dash"

mp4vc="-c:v libx264 -preset ultrafast -crf 24"
mp4ac="-c:a aac -b:a 128k"
vorpac="-c:a libvorbis -ac 2 -aq 9"
opusac="-c:a libopus -ac 2 -b 160000"

speed=$(echo "scale=5; ${2:-1}" | bc)

if [ ! "$speed" -eq "1" ]; then
    echo "adjusting playback speed... [${speed}x]"
    speed_inv=$(echo "scale=5; 1 / ${speed}" | bc)
    filters="$mp4vc $opusac -filter:v setpts=${speed_inv}*PTS -filter:a atempo=${speed}"
    ff="-ff"
fi
cd $path
${tools}/youtube-dl-dash.sh -af $af -vf $vf $ff "$filters" -d $name "$url"

./cast-media-url.py ${dash}/${$name}/stream.mpd 'application/dash+xml'
