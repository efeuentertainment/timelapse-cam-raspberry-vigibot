#!/bin/bash
if [ ! -d /home/pi/timelapse/ ]; then
  mkdir /home/pi/timelapse/
fi

while true
do
  until [ -f /tmp/out.jpg ]
  do
    sleep 0.9
  done
  #echo "File found"
  mv /tmp/out.jpg /home/pi/timelapse/"$(date +%Y%m%d_%H%M%S_%3N)".jpg
  find /home/pi/timelapse/ -mtime +1 -delete
  
  if [[ ! -f /tmp/timelapse_short.mp4 || $(find /tmp/timelapse_short.mp4 -mmin +5) ]]; then
    #date
    echo "recreating timelapse_short.mp4"
    ffmpeg -sseof -1 -r 10 -pattern_type glob -i "/home/pi/timelapse/*.jpg" -s 640x480 -vcodec libx264 /tmp/timelapse_short.mp4 -y >/dev/null 2>&1
    echo "done"
  fi
 
  if [[ ! -f /home/pi/timelapse_long.mp4 || $(find /home/pi/timelapse_long.mp4 -mmin +30) ]]; then
    #date
    #echo "recreating timelapse_long.mp4"
    #ffmpeg -sseof -20 -r 30 -pattern_type glob -i "/home/pi/timelapse/*.jpg" -s 640x480 -vcodec libx264 /home/pi/timelapse_long.mp4 -y >/dev/null 2>&1
    echo "hyuck lol"
  fi

done
exit 0
