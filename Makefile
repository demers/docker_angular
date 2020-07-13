
all: help

help:
	echo
	echo "Usage:"
	echo
	echo "    make create"
	echo
	echo " to create Dockerfile"

create:
	./dockerfile.bash

remove:
	rm -f ./after.vimrc
	rm -f ./extra.vimrc
	rm -f Dockerfile


.SILENT: help
