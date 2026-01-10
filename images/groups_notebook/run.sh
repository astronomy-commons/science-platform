#!/bin/bash
#
# A simple driver to test the container. You'll need to create
# run.env by filling out the missing info in run.env.template
#

#
# About docker volumes: https://docs.docker.com/storage/volumes/
#

# docker volume rm lincc-homes

RUN_ARGS=(
 	-it 
	--rm 
	-p 8888:8888 
	--user=root
	--name jupyter-testuser
	--env-file run.env
	--mount source=lincc-homes,target=/home
	-v $PWD/scripts/startup.sh:/usr/local/bin/startup.sh
	-v $PWD/scripts/get-org-memberships.py:/usr/local/bin/get-org-memberships.py
)
IMAGE=astronomycommons/lincc-notebook:testing
if [ $# == 0 ]; then
	CMD_ARGS=(
		jupyterhub-singleuser
		--ip=0.0.0.0 
		--port=8888 
		--allow-root
	)
else
	CMD_ARGS=("$@")
fi

docker run ${RUN_ARGS[@]} ${IMAGE} ${CMD} ${CMD_ARGS[@]}
