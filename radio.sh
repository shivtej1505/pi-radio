#!/bin/bash
source .env

MPV_PID_FILE=/tmp/mpv.pid
NC_INPUT_FILE=/tmp/nc_input


kill_process() {
	PID_FILE=$1
	if test -f "$PID_FILE"; then
		PID=`cat $PID_FILE`
		kill $PID
		if [ $? -ne 0 ]; then
			echo "no such process";
			return 0;
		fi
		while kill -0 $PID; do
			sleep 1
		done
	fi
}


start() {
	set -x;
	pulseaudio --start;
	touch "$NC_INPUT_FILE";
	while true;
	do
		echo "waiting for start....";
		echo "HTTP/1.1 200 OK\n\n" | nc -l 0.0.0.0 $PORT -N > $NC_INPUT_FILE;
		grep "start" $NC_INPUT_FILE;


		if [ $? -eq 0 ];then
			bluetoothctl connect "$SPEAKER_MAC_ADDR";
			if [ $? -ne 0 ]; then
				echo "Bluetooth connection failed"
				exit 1
			fi

			kill_process "$MPV_PID_FILE";
			mpv -ao=pulse "$STREAM_URL" --volume=70 &
			echo -n "$!" > $MPV_PID_FILE
		fi

		grep "stop" $NC_INPUT_FILE;
		if [ $? -eq 0 ];then
			kill_process "$MPV_PID_FILE";
		fi
	done
}


stop() {
	kill_process "$MPV_PID_FILE";
	rm "$MPV_PID_FILE";
	bluetoothctl disconnect "$SPEAKER_MAC_ADDR";
}

case $1 in
	start|stop) "$1" ;;
esac


