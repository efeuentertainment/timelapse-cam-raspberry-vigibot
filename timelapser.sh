#!/bin/bash
dir=/home/pi/timelapse/
if [ ! -d /home/pi/timelapse/ ]; then
  mkdir /home/pi/timelapse/
fi

echo "current $dir file count: $(ls -1 $dir | wc -l). ready"

while true
do
  until [ -f /tmp/out.jpg ]
  do
    sleep 9
  done

  if [[ ! -f /tmp/1.jpg && ! -f /tmp/2.jpg && ! -f /tmp/3.jpg ]]; then
    mv /tmp/out.jpg /home/pi/timelapse/"$(date +%Y%m%d_%H%M%S_%3N)".jpg
    find /home/pi/timelapse/ -mtime +1 -delete

    if [ $(ls -1 $dir | wc -l) -lt 10 ]; then
      echo "new snapshot found. holding off until at least 10 frames are present. current count: $(ls -1 $dir | wc -l)"
    else

      if [[ ! -f /tmp/timelapse_short.mp4 || $(find /tmp/timelapse_short.mp4 -mmin +5) ]]; then
	#date
	echo "recreating timelapse_short.mp4"
	ffmpeg -sseof -2 -r 10 -pattern_type glob -i "/home/pi/timelapse/*.jpg" -s 640x480 -vcodec libx264 /tmp/timelapse_short.mp4 -y >/dev/null 2>&1
	echo "done"
      fi

      if [[ ! -f /tmp/timelapse_long.mp4 || $(find /tmp/timelapse_long.mp4 -mmin +30) ]]; then
	date
	echo "recreating timelapse_long.mp4"
	ffmpeg -sseof -52 -r 30 -pattern_type glob -i "/home/pi/timelapse/*.jpg" -filter:v "setpts=0.5*PTS" -s 640x480 -vcodec libx264 /tmp/timelapse_long.mp4 -y >/dev/null 2>&1
	echo "done"
      fi
      fi
    else
      echo "found hints of HDR pictures. set EXPOSUREBRACKETING to 0. discarding images..."
      rm /tmp/out.jpg
      rm /tmp/1.jpg
      rm /tmp/2.jpg
      rm /tmp/3.jpg
      fi
    done
    exit 0
