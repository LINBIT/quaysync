#!/bin/bash

set -e

dryrun=n
archs=amd64,s390x
tag=latest
dur=n

help() {
cat <<EOF
$(basename $0) SRCREGISTRY DSTREGISTRY PROJECT
   -a : comma separated list of architectures (default: "$archs")
   -d : run ever N seconds (default: "disabled")
   -h | --help: print help and exit
   -t : Project docker tag (default: "$tag")
      | --dry-run: print command to stdout, but do not execute
EOF
	exit "$1"
}

O=$(getopt -a -l dry-run,help -- a:d:ht: "$@") || exit 1
eval set -- "$O"
while true; do
	case "$1" in
		-a) 			archs="$2";	shift 2;;
		-t) 			tag="$2";	shift 2;;
		-d) 			dur="$2";	shift 2;;
		--dry-run)	dryrun=y;	shift;;
		-h|--help)	help 0;;
		--)			shift; break;;
		*)				echo "Error: '$1'"; help 1;;
	esac
done

[ "$#" = "3" ] || help 1
src_registry="$1"
dst_registry="$2"
project="$3"

declare -A img_hashes

# variables passed by globals, function just there to ease stdout capturing
run() {
	if [ "$dryrun" = 'n' ]; then
		mkdir -p ~/.docker
 		jq '. + {experimental: "enabled"}' /etc/docker/config.json > ~/.docker/config.json
	fi

	echo "rm -rf ~/.docker/manifests"

	src_manifests=""
	for arch in $(echo "$archs" | tr ',' '\n'); do
		src="${src_registry}/${arch}/${project}:${tag}"
		docker pull ${src} &>/dev/null
		cur_hash=$(docker images --format '{{.ID}}' "$src")
		old_hash=${img_hashes[$src]}
		[[ $cur_hash == $old_hash ]] && continue

		img_hashes[$src]=$cur_hash
		dst="${dst_registry}/${project}-${arch}:${tag}"
		echo "docker tag ${src} ${dst}"
		echo "docker push $dst"
		src_manifests="${src_manifests} ${dst}"
	done
	if [ -n "$src_manifests" ]; then
		echo "docker manifest create --insecure --amend ${dst_registry}/${project}:${tag} ${src_manifests}"
		echo "docker manifest push --insecure ${dst_registry}/${project}:${tag}"
	fi
}

while true; do
	[ "$dryrun" = 'y' ] && run || { run | sh; }
	[ "$dur" = 'n' ] && break || sleep "${dur}"
done
