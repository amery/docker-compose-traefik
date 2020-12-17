#!/bin/sh

set -eu
F="$1"
shift

# automatically append empty definitions of new variables
# to config.mk
#
for x; do
	if ! grep -q "^$x " "$F" 2> /dev/null; then
		echo "$x ?=" >> "$F"
	fi
done
