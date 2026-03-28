#!/usr/bin/env bash
set -eo pipefail

DEBUG="${DEBUG:-false}"
pid=""
name="${ICECAST_NAME:?ICECAST_NAME must be set}"
api="${ICECAST_API:?ICECAST_API must be set}"

notify() {
    echo -e "$name started streaming\n$stream" | curl -s -T- ntfy.sh/"$name"_alert
}

is_streaming() {
    [ "$DEBUG" = true ] && [ -e "is_streaming" ] && return 0
    echo "$data" | jq -e '.icestats.source != null' >/dev/null
}

is_recording() {
    [ "$DEBUG" = true ] && [ -e "is_recording" ] && return 0
    [[ -n "$pid" ]] && [[ -n $(ps -p "$pid" -o pid=) ]]
}

start_recording() {
    stream="$(echo "$data" | jq -r '.icestats.source.listenurl')"
    recording="${name}_$(date +"%Y-%m-%dT%H-%M-%S-%3N").mp3"
    log="${recording}.log"
    wget "$stream" -O "$recording" >/dev/null 2>&1 &
    pid=$!
    echo "$data" | jq -r '.icestats.source | "Server Name: \(.server_name)\nServer Description: \(.server_description)\nGenre: \(.genre)"' >>"$log"
}

stop_recording() {
    if [ -n "$pid" ]; then
        kill "$pid" || true
    fi
}

log_songs() {
    echo "$data" | jq -r '.icestats.source | "\(.title)"' >>"$log"
    sort --merge --unique "$log" -o "$log"
}

trap stop_recording EXIT

echo "Started: $(date)"
echo "Name: $name"
echo "API: $api"
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
