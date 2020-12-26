#!/bin/bash

# Chromecast supports: 
#  video:
#    H.264 High Profile up to level 4.1 (720p/60fps or 1080p/30fps)
#    VP8 (720p/60fps or 1080p/30fps)
#  audio:
#    FLAC (up to 96kHz/24-bit)
#    HE-AAC
#    LC-AAC
#    MP3
#    Opus
#    Vorbis
#    WebM

#avc1.42E01E
#avc1.42E01F
#avc1.4D401F
#avc1.4D4028
#avc1.640028
#avc1.640029

#136  mp4     1723k  avc1.4d401f 24fps 1280x536  720p, 26.16MiB
#137  mp4     3225k  avc1.640028 24fps 1920x804 1080p, 45.07MiB

#18   mp4      606k  mp4a.40.2@ 96k (44100Hz),         12.50MiB
#140  m4a_dash 127k  mp4a.40.2@128k (44100Hz),          2.45MiB
#249  webm      53k  opus     @ 50k (48000Hz),          1.02MiB
#250  webm      78k  opus     @ 70k (48000Hz),          1.33MiB
#251  webm     138k  opus     @160k (48000Hz),          2.68MiB

#vf='bestvideo[vcodec=avc1.4d401f]'
#vf='bestvideo[container=mp4]'
vf=136
#af='bestaudio[acodec=mp4a.40.2]'
#af='bestaudio[container=m4a_dash]/bestaudio[container=mp4]'
#af=251
af=140

# from mkchromecast:
# -map_chapters -1 -vcodec libx264 -preset ultrafast -tune zerolatency -maxrate 10000k -bufsize 20000k 
# -pix_fmt yuv420p -g 60 -f mp4 -max_muxing_queue_size 9999 -movflags frag_keyframe+empty_moov 

# libx264 libopenh264 aac libfdk_aac
port=55987

#url="https://www.youtube.com/watch?v=Cs32gaFg4mo"
#url="https://www.youtube.com/watch?v=x5HjZcz_GC8"
#url="https://www.youtube.com/watch?v=OQTImQ0RQNg"
url=$1

name=$( echo $url | sed -E -e 's/^.*\?v=([a-zA-Z0-9]*).*$/\1/' )

speed=$(echo "scale=5; ${2:-1}" | bc)

mp4mx=" -f mp4 -movflags frag_keyframe+empty_moov pipe:1 "
#rtmpmx=" -f flv $rtmp_sink "
dashmx=" -movflags frag_keyframe+empty_moov -f dash stream.mpd "

passthroughvc=" -c:v copy "
passthroughac=" -c:a copy "
mp4vc=" -c:v libx264 -preset ultrafast -crf 24 "
mp4ac=" -c:a aac -b:a 128k -ac 2 "

mx=$dashmx

filters=""
vc=$passthroughvc
ac=$passthroughac
if [ ! "$speed" -eq "1" ]; then
    echo "adjusting playback speed... [${speed}x]"
    speed_inv=$(echo "scale=5; 1 / ${speed}" | bc)
    filters=" ${filters} -filter:v setpts=${speed_inv}*PTS -filter:a atempo=${speed} "
    vc=$mp4vc
    ac=$mp4ac
fi

mkdir -p ./.${name}
cd ./.${name}
rm audio_stream video_stream 2> /dev/null
mkfifo audio_stream
mkfifo video_stream

echo "queueing downloads..."
youtube-dl -q -f $vf -o - "$url" > video_stream &
youtube-dl -q -f $af -o - "$url" > audio_stream &

echo "muxing..."
ffmpeg \
    -thread_queue_size 8000 \
    -i video_stream \
    -thread_queue_size 8000 \
    -i audio_stream \
    $vc \
    $ac \
    $filters \
    $mx &

echo -n "waiting for segment.."
while ! test -f "stream.mpd"; do
    sleep 1
    echo -n "."
done
echo ""

stream="ffmpeg \
    -re \
    -i stream.mpd \
    $passthroughvc \
    $passthroughac \ 
    $mp4mx"

echo "casting..."
mkchromecast -p $port --video --command "$stream"
