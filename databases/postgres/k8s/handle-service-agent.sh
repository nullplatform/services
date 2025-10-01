#!/bin/bash -x
env
WORKING_DIRECTORY="$(dirname "$(realpath "$0")")"
cd "$WORKING_DIRECTORY" || exit 1

echo "Starting handle agent service"

echo "📩 Notification received: $NP_ACTION_CONTEXT"
eval "$(np service-action export-action-data --format bash --bash-prefix ACTION)"
np service-action exec --live-output --live-report --debug 
exit $?