#!/usr/bin/env bash
set -eo pipefail

name="shamiradio"
api="https://shamiradio.imgoodatth.is/status-json.xsl"
stream="https://shamiradio.imgoodatth.is/main.mp3"

notify() {
    echo -e "$name started streaming\n$stream" | curl -s -T- ntfy.sh/"$name"_alert
}

is_streaming() {
    [ "$DEBUG" = true ] && [ -e "is_streaming" ] && return 0
    echo "$data" | jq -e '.icestats.source != null' >/dev/null
}

is_recording() {
    [ "$DEBUG" = true ] && [ -e "is_recording" ] && return 0
    [[ -n "$pid" ]] && [[ -n $(ps -p $pid -o pid=) ]]
}

start_recording() {
    recording="${name}_$(date +"%Y-%m-%dT%H-%M-%S-%3N").mp3"
    log="${recording}.log"
    wget "$stream" -O "$recording" >/dev/null 2>&1 &
    pid=$!
    echo "$data" | jq -r '.icestats.source | "Server Name: \(.server_name)\nServer Description: \(.server_description)\nGenre: \(.genre)"' >>"$log"
}

stop_recording() {
    [ -n "$pid" ] && kill "$pid" || true
}

log_songs() {
    echo "$data" | jq -r '.icestats.source | "\(.title)"' >>"$log"
    sort --merge --unique "$log" -o "$log"
}

trap stop_recording EXIT

while true; do
    data=$(curl -s "$api")
    if ! is_recording && is_streaming; then
        start_recording
        echo "Recording started: $recording"
        notify
        log_songs
    elif is_recording && ! is_streaming; then
        stop_recording
        echo "Recording stopped: $recording"
        log_songs
    elif is_recording && is_streaming; then
        log_songs
    fi
    sleep 60
done
