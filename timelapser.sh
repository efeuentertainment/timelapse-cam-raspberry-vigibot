#!/bin/bash
#created by firened
#guide on GitHub: https://github.com/efeuentertainment/timelapse-cam-raspberry-vigibot

#path to where photos shall be stored
dir=/home/pi/timelapse/

if [ "$(id -u)" != "0" ]; then
  echo "Please run as root"
  exit 1
fi

#create dir
if [ ! -d $dir ]; then
  mkdir $dir
fi

echo "current $dir file count: $(ls -1 $dir | wc -l). waiting for snapshots (robot must be asleep)"

while true
do
  #wait until new snapshot is detected
  #vigibot SNAPSHOTINTERVAL: 1 creates 60 photos per hour
  until [ -f /tmp/out.jpg ]
  do
    sleep 9
  done
  
  #throw error if HDR files are detected, they stop ffmpeg, perhaps because the HDR processing may not be done yet, resulting in corrupt files.
  if [[ -f /tmp/1.jpg || -f /tmp/2.jpg || -f /tmp/3.jpg ]]; then
    echo "found hints of HDR pictures. set hw config -> EXPOSUREBRACKETING to 0 and delete /tmp/*.jpg (or reboot). discarding snapshot..."
    rm /tmp/out.jpg
  else

    #rename new snapshot to current timestamp and delete pjotos older than 1 day (48h)
    mv /tmp/out.jpg "$dir $(date +%Y%m%d_%H%M%S_%3N)".jpg
    find "$dir" -mtime +1 -delete

    #print info below 61 photos.
    if [ $(ls -1 $dir | wc -l) -lt 61 ]; then
      echo "new snapshot found. timelapse_long might need as many as 60 frames to work properly. current count: $(ls -1 $dir | wc -l)"
    fi
    #skip creation below 10 photos.
    if [ $(ls -1 $dir | wc -l) -lt 10 ]; then
      echo "holding off creation until at least 10 frames are present."
    else

      #create timelapse_short every 5 min.
      if [[ ! -f /tmp/timelapse_short.mp4 || $(find /tmp/timelapse_short.mp4 -mmin +5) ]]; then
	echo "creating timelapse_short.mp4 ..."
        #target length: 1h in 6s playback
	#'-sseof 2': use only most recent 2 seconds of input
	#ffmpeg may be assuming a different fps value in its -sseof calculation
        #'-r 10': set conversion to 10 fps
	#'-filter:v fps=fps=30': force 30 fps output so thr 30 fps vigibot captures work
	ffmpeg -sseof -2 -r 10 -pattern_type glob -i "$dir*.jpg" -s 640x480 -vcodec libx264 -filter:v fps=fps=30 /tmp/timelapse_short.mp4 -y >/dev/null 2>&1
	echo "timelapse_short.mp4 done!"
      fi

      #create timelapse_long every 30 min
      if [[ ! -f /tmp/timelapse_long.mp4 || $(find /tmp/timelapse_long.mp4 -mmin +30) ]]; then
	date
	echo "creating timelapse_long.mp4 ..."
        #target length: about 24h in 40s playback
	#"-sseof 52": use only most recent 52 seconds of input
	#ffmpeg may be assuming a different fps value in its -sseof calculation
        #'-r 30': set conversion to 30 fps
	#'-filter:v "setpts=0.5*PTS"': only pass 50% of the frames, drop the others. this halves timelapse_long playback duration. (e.g. '0.2' would only pass 20% of the frames).
	ffmpeg -sseof -52 -r 30 -pattern_type glob -i "$dir*.jpg" -filter:v "setpts=0.5*PTS" -s 640x480 -vcodec libx264 /tmp/timelapse_long.mp4 -y >/dev/null 2>&1
	echo "timelapse_long.mp4 done!"
      fi
    fi
  fi
done
exit 0
