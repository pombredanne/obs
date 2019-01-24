#!/bin/sh
# Get a list of the slaves from master.json
set -e
sed -e '1,$s/, "comment.*//' -e '1,/"slaves"/d' -e '/]/,$d' < master.json | sed 's/.*:"//;s/".*//' | sort -u
