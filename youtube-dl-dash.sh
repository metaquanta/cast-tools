#!/bin/bash

# Defaults
vf="bestvideo"
af="bestaudio"

defaultffopts="-c:v copy -c:a copy -movflags frag_keyframe+empty_moov"

ffopts=""
ytdlopts=""
while (( "$#" )); do
    case "$1" in
        -h|--help)
            cat <<EOF
Usage: $0 [OPTIONS] [youtube-dl OPTIONS ...]

Options:
    -h, --help
    -af, --audio-format   "$af"
    -vf, --video-format   "$vf"
    -ff, --ffmpeg-options "$defaultffopts"
    -d, --directory-name  <...........>
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
        -ff|--ffmpeg-options)
            ffopts="$ffopts $2"
            shift 2
            ;;
        -d|--directory-name)
            name=$2
            shift 2
            ;;
        *) # pass the rest on to youtube-dl
            ytdlopts="$ytdlopts $1"
            shift
            ;; 
    esac
done

ffopts=${ffopts:-$defaultffopts}
name=${name:-$( echo $ytdlopts | sed -E -e 's/^.*\?v=([a-zA-Z0-9]*).*$/\1/' )}

#echo af=[$af] vf=[$vf] ff=[$ffopts] ytdlopts=[$ytdlopts] name=[$name]

mkdir -p ./${name}
cd ./${name}
rm .audio_stream .video_stream 2> /dev/null
mkfifo .audio_stream
mkfifo .video_stream

echo "downloading..."
youtube-dl -q -f $vf -o - $ytdlopts > .video_stream &
youtube-dl -q -f $af -o - $ytdlopts > .audio_stream &

echo "muxing..."
ffmpeg -loglevel 16 \
    -thread_queue_size 8000 \
    -i .video_stream \
    -thread_queue_size 8000 \
    -i .audio_stream \
    $ffopts \
    -f dash stream.mpd &

echo -n "waiting for segment.."
while ! test -f "stream.mpd"; do
    sleep 1
    echo -n "."
done
echo ""
echo $(realpath ./stream.mpd)
