#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

version=$(sed -n 's/^version="\(.*\)"$/\1/p' addons/hengo/plugin.cfg)
if [ -z "$version" ]; then
	echo 'plugin.cfg: version not found' >&2
	exit 1
fi

out_dir=${1:-dist}
out="$out_dir/hengo-$version.zip"

# git stash create skips untracked files, so a new action would leave the zip silently
untracked=$(git ls-files --others --exclude-standard addons/hengo)
if [ -n "$untracked" ]; then
	echo 'untracked files under addons/hengo, commit or remove them first:' >&2
	echo "$untracked" >&2
	exit 1
fi

# git stash create archives the working tree without touching the branch or the stash list
tree=$(git stash create)

mkdir -p "$out_dir"
rm -f "$out"
git archive --format=zip --output="$out" "${tree:-HEAD}"

roots=$(unzip -Z1 "$out" | cut -d/ -f1 | sort -u)
if [ "$roots" != 'addons' ]; then
	echo "unexpected roots in the zip: $roots" >&2
	exit 1
fi

echo "$out"
echo "files: $(unzip -Z1 "$out" | grep -vc '/$')"
