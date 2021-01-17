#!/bin/bash

a="-c:a copy"
v="-c:v copy"

while (( "$#" )); do
    case "$1" in
        -h|--help)
            cat <<EOF
Usage: $0 [OPTIONS] <url>

Options:
    -h, --help
    -a, --audio-transcode
    -v, --video-transcode
EOF
            exit 1
            ;;
        -a|--audio-format)
            a="-c:a libopus -ac 2 -b:a 150000"
	    #a="-c:a libvorbis -ac 2 -aq 9"
            shift 1
            ;;
        -v|--video-format)
            v="-c:v libx264 -preset ultrafast -crf 24"
            shift 1
            ;;
        *) 
	    file="$1"
            shift
            ;;
    esac
done

self=$( which $0 )
tools=$( realpath "${self%/*}" )

addr=$( hostname -I | cut -f 1 -d \  )
path="/var/www/html/dash"
dash="http://${addr}/dash"

dir=$( md5sum "$file" | cut -d \  -f 1 )
afile=$( realpath "$file" )

cd $path
${tools}/transcode-dash.sh -a "$a" -v "$v" -d "$dir" "$afile"
#echo dash=[$dash] name=[$name]
echo "serving from ${dash}/${dir}/stream.mpd"
echo "casting..."
${tools}/cast-media-url.py "${dash}/${dir}/stream.mpd" 'application/dash+xml'
