#!/bin/bash

# Defaults

ff=""
af="-c:a copy"
vf="-c:v copy"

while (( "$#" )); do
    case "$1" in
        -h|--help)
            cat <<EOF
Usage: $0 [OPTIONS] <video>

Options:
    -h, --help
    -a, --transcode-audio   "$af"
    -v, --transcode-video   "$vf"
    -f, --filter            "$ff"
    -d, --directory-name    <...........>
EOF
            exit 1
            ;;
        -a|--transcode-audio) 
            af=$2 
            shift 2 
            ;;
        -v|--transcode-video)
            vf=$2
            shift 2
            ;;
        -f|--filter)
            ff="$2"
            shift 2
            ;;
        -d|--directory-name)
            name=$2
            shift 2
            ;;
        *) 
            video=$( realpath "$1" )
            shift
            ;; 
    esac
done

#name=${name:-$( echo $video | sed -E -e 's/^.*\?v=([a-zA-Z0-9]*).*$/\1/' )}

echo ff=[$ff] af=[$af] vf=[$vf] name=[$name] video=[$video]

mkdir -p ${name}
cd ${name}

ffmpeg \
    -i "$video" \
    $af $vf $ff \
    -loglevel 24 \
    -movflags frag_keyframe+empty_moov \
    -f dash \
    stream.mpd &

echo -n "waiting for segment.."
while ! test -f "stream.mpd"; do
    sleep 1
    echo -n "."
done
echo ""

echo $(realpath stream.mpd)
