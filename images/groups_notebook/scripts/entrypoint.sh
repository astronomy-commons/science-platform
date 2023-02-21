#!/bin/bash

echo "Running command ${1}"

# Check the command that is trying to be run in the container
# and pass that command to the start-spark script in case we are
# trying to launch a spark worker
case "$1" in
    # We are in spark land
    driver | driver-py | driver-r | executor)
      source /usr/local/bin/pre-start-source.sh
      export CONTAINER_TYPE="spark"
      CMD=("/usr/local/bin/start.sh"
           "/usr/local/bin/start-spark.sh"
           "$@"
          )
      ;;
    start-ssh.sh)
      export CONTAINER_TYPE="ssh"
      CMD=("/usr/local/bin/start.sh"
           "/usr/local/bin/start-ssh.sh"
           "$@")
      ;;
    /bin/bash | bash | /bin/sh | sh)
      export CONTAINER_TYPE="shell"
      CMD=("/usr/local/bin/start.sh"
           "$@")
      ;;
    # We are spawning a single user notebook session, a dask worker, or something else
    # Just pass the command through
    *)
      source /usr/local/bin/pre-start-source.sh
      export CONTAINER_TYPE="notebook"
      CMD=("/usr/local/bin/start-notebook.sh"
           "${@:2}")
      ;;
esac

# Run the command
echo "${CMD[@]}"
exec "${CMD[@]}"
