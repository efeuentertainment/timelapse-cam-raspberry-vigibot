#!/bin/bash
dir=/home/pi/timelapse/

if [ "$(id -u)" != "0" ]; then
  echo "Please run as root"
  exit 1
fi

if [ ! -d $dir ]; then
  mkdir $dir
fi
echo "current $dir file count: $(ls -1 $dir | wc -l). waiting for snapshots (robot must be asleep)"

while true
do
  until [ -f /tmp/out.jpg ]
  do
    sleep 9
  done

  if [[ -f /tmp/1.jpg || -f /tmp/2.jpg || -f /tmp/3.jpg ]]; then
    echo "found hints of HDR pictures. set hw config -> EXPOSUREBRACKETING to 0 and delete /tmp/*.jpg (or reboot). discarding snapshot..."
    rm /tmp/out.jpg
  else
    mv /tmp/out.jpg /home/pi/timelapse/"$(date +%Y%m%d_%H%M%S_%3N)".jpg
    find /home/pi/timelapse/ -mtime +1 -delete

    if [ $(ls -1 $dir | wc -l) -lt 61 ]; then
      echo "new snapshot found. timelapse_long might need as many as 60 frames to work properly. current count: $(ls -1 $dir | wc -l)"
    fi
    if [ $(ls -1 $dir | wc -l) -lt 10 ]; then
      echo "holding off creation until at least 10 frames are present."
    else

      if [[ ! -f /tmp/timelapse_short.mp4 || $(find /tmp/timelapse_short.mp4 -mmin +5) ]]; then
	#date
	echo "creating timelapse_short.mp4 ..."
	ffmpeg -sseof -2 -r 10 -pattern_type glob -i "/home/pi/timelapse/*.jpg" -s 640x480 -vcodec libx264 /tmp/timelapse_short.mp4 -y >/dev/null 2>&1
	echo "timelapse_short.mp4 done!"
      fi

      if [[ ! -f /tmp/timelapse_long.mp4 || $(find /tmp/timelapse_long.mp4 -mmin +30) ]]; then
	date
	echo "creating timelapse_long.mp4 ..."
	ffmpeg -sseof -52 -r 30 -pattern_type glob -i "/home/pi/timelapse/*.jpg" -filter:v "setpts=0.5*PTS" -s 640x480 -vcodec libx264 /tmp/timelapse_long.mp4 -y >/dev/null 2>&1
	echo "timelapse_long.mp4 done!"
      fi
    fi
  fi
done
exit 0
