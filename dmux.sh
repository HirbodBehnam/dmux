#!/bin/bash
# First argument must be the the name of the image
if [ $# -lt 1 ]; then
	echo "Please provide at least one argument to program. Possible arguments:"
	echo "	<image>: Create a new container with given image name"
	echo "	a: Attach to last container"
	echo "	a <name>: Attach to given dmux container"
	echo "	sh: Spawn shell in the last container"
	echo "	sh <name>: Spawn shell in the given dmux container"
	echo "	v: Remount the working directory of the last container to current working directory"
	echo "	v <name>: Remount the working directory of given container to current working directory"
	echo "	rm: Remove all dmux containers"
	echo "	rm <name>: Remove given demux container"
	echo "	ls: List all dmux containers"
	exit 1
fi
# Create the config directory/files
mkdir -p ~/.config/dmux
mkdir -p ~/.cache/dmux
touch ~/.config/dmux/alias
# This function will check the alias of a command in the first argument.
# The result will be returned in IMAGE_NAME.
# If there is no alias, the result will be the same as input.
function get_alias_image_name() {
	IMAGE_VERSION=$(cut -sd':' -f 2 <<< "$1") # might be empty
	IMAGE_NAME=$(cut -d':' -f 1 <<< "$1")
	# Check the filename
	while IFS= read -r line; do
		if [[ $(cut -f1 <<< "$line") == "$IMAGE_NAME" ]]; then
			IMAGE_NAME=$(cut -f2 <<< "$line")
			break
		fi
	done < ~/.config/dmux/alias
	# Concat the version if needed
	if [ -n "$IMAGE_VERSION" ]; then
		IMAGE_NAME+=":$IMAGE_VERSION"
	fi
	unset IMAGE_VERSION
}
# Gets the container name based on the arguments of the script.
# Either returns the name of the last dmux container or returns
# the container name based on the arguments.
# The result will be put into a variable called CONTAINER_NAME
# This function must be called with the arguments of the script (infer_container_name "$@").
function infer_container_name() {
	# Infer the container name...
	if [ $# -lt 2 ]; then # ...from the last container used
		CONTAINER_NAME="$(docker ps -a --format '{{.Names}}' | grep '^dmux-' | head -n 1)"
	else # ...from command line argument
		CONTAINER_NAME="dmux-$2"
	fi
}
# Check flags
case "$1" in
	# Attach to container
	"a")
		infer_container_name "$@"
		if ! docker ps -a | grep -q "$CONTAINER_NAME"; then
			echo "Container $CONTAINER_NAME does not exists"
			exit 1
		fi
		# Attach to it!
		echo "Attaching to $CONTAINER_NAME"
		docker start -a -i "$CONTAINER_NAME"
		;;
	# Create shell in container
	"sh")
		infer_container_name "$@"
		if ! docker ps -a | grep -q "$CONTAINER_NAME"; then
			echo "Container $CONTAINER_NAME does not exists"
			exit 1
		fi
		# Attach to it!
		echo "Starting shell in $CONTAINER_NAME"
		docker exec -it "$CONTAINER_NAME" bash
		;;
	# Remove container
	"rm")
		if [ $# -lt 2 ]; then # remove everything
			docker ps -a --format '{{.Names}}' | grep '^dmux-' | xargs docker rm
			rm -rf ~/.cache/dmux/workdir-*
		else # Remove one container
			docker rm "dmux-$2"
			rm -rf "$HOME/.cache/dmux/workdir-dmux-$2"
		fi
		;;
	# List dmux containers
	"ls")
		docker ps -a --format '{{.Names}}' | grep '^dmux-' | cut -c 6-
		;;
	# Remount the working directory
	"v")
		infer_container_name "$@"
		# Delete the sym link
		rm -rf "$HOME/.cache/dmux/workdir-$CONTAINER_NAME"
		# Create a new one
		echo "Remounting $CONTAINER_NAME workdir to $(pwd)"
		ln -s "$(pwd)" "$HOME/.cache/dmux/workdir-$CONTAINER_NAME"
		;;
	# Create a new container
	*)
		get_alias_image_name "$1"
		CONTAINER_NAME=$(printf "%s" "dmux-$1" | tr -c 'a-zA-Z0-9._' '-') # Docker only allows specific characters in container name
		echo "Creating container $CONTAINER_NAME from image $IMAGE_NAME"
		ln -s "$(pwd)" "$HOME/.cache/dmux/workdir-$CONTAINER_NAME"
		docker run -it -v "$HOME/.cache/dmux/workdir-$CONTAINER_NAME/:/workdir" -w /workdir --hostname "$CONTAINER_NAME" --name "$CONTAINER_NAME" "$IMAGE_NAME" bash
		;;
esac
