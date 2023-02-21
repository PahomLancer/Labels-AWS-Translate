#!/bin/bash

########################################
######## Mock Service Launcher ########
########################################
## Configuration environment variables:
# SERVICE_PID - path to pid file
# SERVICE_OUT - path to standard output log file
# SERVICE_COMMAND - Command to run service
########################################

if [ -z "$SERVICE_PID" ]; then
    echo "SERVICE_PID is not set"
    exit 1
fi
if [ -z "$SERVICE_OUT" ]; then
    echo "SERVICE_OUT is not set"
    exit 1
fi
if [ -z "$SERVICE_COMMAND" ]; then
    echo "SERVICE_COMMAND is not set"
    exit 1
fi

# shellcheck disable=SC2209
_NOHUP=nohup

if [ -f "$SERVICE_PID" ]; then
    if [ -s "$SERVICE_PID" ]; then
        echo "Existing PID file found during start."
        if [ -r "$SERVICE_PID" ]; then
            PID=$(cat "$SERVICE_PID")
            if ps -p "$PID" >/dev/null 2>&1; then
                echo "Service appears to still be running with PID $PID. Start aborted."
                echo "If the following process is not a service process, remove the PID file and try again:"
                ps -f -p "$PID"
                exit 1
            else
                echo "Removing/clearing stale PID file."
                if ! rm -f "$SERVICE_PID" >/dev/null 2>&1; then
                    if [ -w "$SERVICE_PID" ]; then
                        cat /dev/null >"$SERVICE_PID"
                    else
                        echo "Unable to remove or clear stale PID file. Start aborted."
                        exit 1
                    fi
                fi
            fi
        else
            echo "Unable to read PID file. Start aborted."
            exit 1
        fi
    else
        if ! rm -f "$SERVICE_PID" >/dev/null 2>&1; then
            if [ ! -w "$SERVICE_PID" ]; then
                echo "Unable to remove or write to empty PID file. Start aborted."
                exit 1
            fi
        fi
    fi
fi

# shellcheck disable=SC2086
eval $_NOHUP "\"$SERVICE_COMMAND\"" $SERVICE_ARGS "&" >"$SERVICE_OUT" 2>&1

echo $! >"$SERVICE_PID"
echo "Service started."
