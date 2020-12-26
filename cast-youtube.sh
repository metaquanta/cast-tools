#!/bin/bash

#vf='bestvideo[vcodec=avc1.4d401f]'
#vf='bestvideo[container=mp4]'
vf=136/137/22
#af='bestaudio[acodec=mp4a.40.2]'
#af='bestaudio[container=m4a_dash]/bestaudio[container=mp4]'
af=251/bestaudio

speed=1

while (( "$#" )); do
    case "$1" in
        -h|--help)
            cat <<EOF
Usage: $0 [OPTIONS] <url>

Options:
    -h, --help
    -af, --audio-format   "$af"
    -vf, --video-format   "$vf"
    -s, --speed           "$speed"
    --sound-track         <...........>
EOF
            exit 1
            ;;
        -af|--audio-format)
            af=$2
            shift 2
            ;;
        -vf|--video-format)
            vf=$2
            shift 2
            ;;
        -s|--speed)
            speed="$2"
            shift 2
            ;;
        --sound-track)
            soundtrack=$2
            shift 2
	    echo "WiP"
	    exit 1
            ;;
        *) # pass the rest on to youtube-dl
            url="$1"
            shift
            ;;
    esac
done

self=$( which $0 )
tools=$( realpath "${self%/*}" )
name=$( echo $url | sed -E -e 's/^.*\?v=([_a-zA-Z0-9]*).*$/\1/' )

path="/var/www/html/dash"
dash="http://192.168.31.202/dash"

mp4vc="-c:v libx264 -preset ultrafast -crf 24"
mp4ac="-c:a aac -ac 2 -b:a 128k"
vorpac="-c:a libvorbis -ac 2 -aq 9"
opusac="-c:a libopus -ac 2 -b:a 128000"

speed=$(echo "scale=5; ${2:-1}" | bc)

if [ ! "$speed" == "1" ]; then
    echo "adjusting playback speed... [${speed}x]"
    speed_inv=$(echo "scale=5; 1 / ${speed}" | bc)
    filters="$mp4vc $opusac -filter:v setpts=${speed_inv}*PTS -filter:a atempo=${speed}"
    ff="-ff"
elif [ ! -z $soundtrack ]; then
    echo "mixing soundtrack..."
fi

cd $path
${tools}/youtube-dl-dash.sh -af $af -vf $vf $ff "$filters" -d $name "$url"
#echo dash=[$dash] name=[$name]
echo "casting..."
${tools}/cast-media-url.py "${dash}/${name}/stream.mpd" 'application/dash+xml'
