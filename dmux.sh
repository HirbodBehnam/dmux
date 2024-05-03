#!/bin/bash
# First argument must be the the name of the image
if [ $# -lt 1 ]; then
	echo "Please provide at least one argument to program. Possible arguments:"
	echo "	<image>: Create a new container with given image name"
	echo "	a: Attach to last container"
	echo "	a <name>: Attach to given dmux container"
	echo "	rm: Remove all dmux containers"
	echo "	rm <name>: Remove given demux container"
	echo "	ls: List all dmux containers"
	exit 1
fi
# Check flags
case "$1" in
	# Attach to container
	"a")
		# Infer the container name...
		if [ $# -lt 2 ]; then # ...from the last container used
			CONTAINER_NAME="$(docker ps -a --format '{{.Names}}' | grep '^dmux-' | head -n 1)"
		else # ...from command line argument
			CONTAINER_NAME="$2"
		fi
		# Check if container exists
		if [[ "$CONTAINER_NAME" == "" ]]; then
			echo "Cannot attach to nothing"
			exit 1
		fi
		if ! docker ps -a | grep -q "$CONTAINER_NAME"; then
			echo "Container $CONTAINER_NAME does not exists"
			exit 1
		fi
		# Attach to it!
		echo "Attaching to $CONTAINER_NAME"
		docker start -a -i "$CONTAINER_NAME"
		;;
	# Remove container
	"rm")
		if [ $# -lt 2 ]; then # Remove everything
			docker ps -a --format '{{.Names}}' | grep '^dmux-' | xargs docker rm
		else # Remove one container
			docker rm "dmux-$2"
		fi
		;;
	# List dmux containers
	"ls")
		docker ps -a --format '{{.Names}}' | grep '^dmux-' | cut -c 6-
		;;
	# Create a new container
	*)
		CONTAINER_NAME="dmux-$1"
		echo "Creating container $CONTAINER_NAME"
		docker run -it -v "$(pwd):/workdir" -w /workdir --hostname "$CONTAINER_NAME" --name "$CONTAINER_NAME" "$1" bash
		;;
esac