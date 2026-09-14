#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

version=$(sed -n 's/^version="\(.*\)"$/\1/p' addons/hengo/plugin.cfg)
if [ -z "$version" ]; then
	echo 'plugin.cfg: version not found' >&2
	exit 1
fi

out_dir=${1:-dist}
slim="$out_dir/hengo-$version.zip"
full="$out_dir/hengo-$version-with-tools.zip"

# git stash create skips untracked files, so a new action would leave the zip silently
untracked=$(git ls-files --others --exclude-standard addons/hengo tools)
if [ -n "$untracked" ]; then
	echo 'untracked files under addons/hengo or tools, commit or remove them first:' >&2
	echo "$untracked" >&2
	exit 1
fi

# git stash create archives the working tree without touching the branch or the stash list
tree=$(git stash create)

mkdir -p "$out_dir"
rm -f "$slim" "$full"
git archive --format=zip --output="$slim" "${tree:-HEAD}" addons
git archive --format=zip --output="$full" "${tree:-HEAD}" addons tools

check_roots() {
	local roots
	roots=$(unzip -Z1 "$1" | cut -d/ -f1 | sort -u | tr '\n' ' ')
	if [ "$roots" != "$2 " ]; then
		echo "unexpected roots in $1: $roots" >&2
		exit 1
	fi
}

check_roots "$slim" 'addons'
check_roots "$full" 'addons tools'

if unzip -Z1 "$full" | grep -qx 'tools/make_release.sh'; then
	echo "$full ships tools/make_release.sh, check .gitattributes" >&2
	exit 1
fi

for zip in "$slim" "$full"; do
	echo "$zip"
	echo "files: $(unzip -Z1 "$zip" | grep -vc '/$')"
done
