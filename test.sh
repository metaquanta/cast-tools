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
#    WAV (LPCM)
#    WebM

#18   mp4   640x268    360p  606k , avc1.42001E, 24fps, mp4a.40.2@ 96k (44100Hz), 12.50MiB      # Only combined
#133  mp4   426x178    240p  182k , avc1.4d400d, 24fps, video only, 2.94MiB
#134  mp4   640x268    360p  471k , avc1.4d4015, 24fps, video only, 7.25MiB
#135  mp4   854x358    480p  863k , avc1.4d401e, 24fps, video only, 14.37MiB                    # 480p Video (mp4)
#136  mp4   1280x536   720p 1723k , avc1.4d401f, 24fps, video only, 26.16MiB                    # Acceptable Video (mp4)
#137  mp4   1920x804   1080p 3225k , avc1.640028, 24fps, video only, 45.07MiB
#140  m4a   audio only tiny  127k , m4a_dash container, mp4a.40.2@128k (44100Hz), 2.45MiB       # Only Audio (mp4)
#160  mp4   256x144    144p  110k , avc1.4d400c, 25fps, video only, 3.04MiB
#242  webm  426x240    240p  224k , vp9, 30fps, video only, 2.77MiB
#243  webm  640x268    360p  304k , vp9, 24fps, video only, 5.51MiB
#244  webm  854x480    480p  759k , vp9, 30fps, video only, 8.91MiB
#247  webm  1280x536   720p 1122k , vp9, 24fps, video only, 19.76MiB
#248  webm  1920x804   1080p 1988k , vp9, 24fps, video only, 34.69MiB
#249  webm  audio only tiny   53k , opus @ 50k (48000Hz), 1.02MiB
#250  webm  audio only tiny   78k , opus @ 70k (48000Hz), 1.33MiB
#251  webm  audio only tiny  138k , opus @160k (48000Hz), 2.68MiB                               # Best Audio (webm)
#271  webm  2560x1070  1440p 6508k , vp9, 24fps, video only, 97.43MiB
#278  webm  256x108    144p   74k , webm container, vp9, 24fps, video only, 1.44MiB
#394  mp4   256x108    144p   63k , av01.0.00M.08, 24fps, video only, 1.18MiB
#395  mp4   426x178    240p  136k , av01.0.00M.08, 24fps, video only, 2.38MiB
#396  mp4   640x268    360p  295k , av01.0.01M.08, 24fps, video only, 4.67MiB
#397  mp4   854x358    480p  530k , av01.0.04M.08, 24fps, video only, 8.12MiB
#398  mp4   1280x536   720p 1160k , av01.0.05M.08, 24fps, video only, 16.31MiB
#399  mp4   1920x804   1080p 1995k , av01.0.08M.08, 24fps, video only, 27.55MiB
#400  mp4   2560x1070  1440p 5491k , av01.0.12M.08, 24fps, video only, 77.76MiB

# from mkchromecast:
# -map_chapters -1 -vcodec libx264 -preset ultrafast -tune zerolatency -maxrate 10000k -bufsize 20000k 
# -pix_fmt yuv420p -g 60 -f mp4 -max_muxing_queue_size 9999 -movflags frag_keyframe+empty_moov 


rm audio_stream video_stream combined

mkfifo audio_stream
mkfifo video_stream
mkfifo combined

url="https://www.youtube.com/watch?v=Cs32gaFg4mo"
# https://www.youtube.com/watch?v=x5HjZcz_GC8
# https://www.youtube.com/watch?v=OQTImQ0RQNg

#speed=${2:-1}
speed="2"

mp4af=140
mp4vf=136
#vf='bestvideo[vcodec!=vp9][height<=720]'
#af='bestaudio'

speed_filters=""
video_codec=" -c:v copy "
audio_codec=" -c:a copy "
#if [ -v "1" ] && [ "$1" -ne "1" ]; then
#if [ ! "$speed" = "1" ]; then
echo "calc speed"
    _sp=$(echo "scale=5; $speed" | bc)
    _sp_inv=$(echo "scale=5; 1 / ${_sp}" | bc)
    speed_filters=" -filter:v setpts=${_sp_inv}*PTS -filter:a atempo=${_sp} "
    video_codec=" -c:v libx264 -preset ultrafast -crf 24 "
    audio_codec=" -c:a aac -b:a 127k "
#fi
echo "$_sp speed"
webm=" -f webm "
mp4=" -f mp4 -movflags frag_keyframe+empty_moov "

echo "queueing downloads..."
youtube-dl -q -f $mp4vf -o - "$url" > video_stream &
youtube-dl -q -f $mp4af -o - "$url" > audio_stream &

sleep 1

echo "muxing..."
ffmpeg \
    -thread_queue_size 8000 \
    -i video_stream \
    -thread_queue_size 8000 \
    -i audio_stream \
    $video_codec \
    $audio_codec \
    $speed_filters \
    $mp4 \
    pipe:1 > combined &
 
 sleep 1

 echo "calling chromecast..."
 #mkchromecast --video --command 'ffmpeg -re -i combined -c copy pipe:1'