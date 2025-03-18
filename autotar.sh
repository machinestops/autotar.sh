#!/bin/sh -e

# automatically produces an archive file from a directory that will self-extract and run a script within

p   () { printf '%s\n' "$*"; }
err () { 
    log "$*" 1>&2
    cat << EOF 1>&2
Usage: autotar.sh FILE DIRECTORY
Produce executable gzip-compressed self-extracting archives from DIRECTORY.
DIRECTORY must contain 'autorun.sh', which is executed when the archive extracts itself.
}

dest=${1:?no file provided}
src=${2:?no directory provided}

prelude=$(mktemp -t tmp.XXXXXX)

cat << 'EOF' > $prelude
tmpdir=$(mktemp -d)
tail -n+"$size" < "$0" | gzip -dc | tar xf - -C "$tmpdir"
"$tmpdir/autorun.sh" "$tmpdir"
rm -rf "$tmpdir"

exit 0
EOF

trap  "rm -f $prelude" INT 
trap "rm -f $prelude" EXIT

[ -d "$src" ]  || err "'$src' not a directory"

echo '#!/bin/sh' > ${dest}
echo "size=$(( 3 + $(wc -l < $prelude) ))" >> "$dest"
cat "$prelude" >> "$dest"
tar cf - -C "$src" . | gzip -c >> "$dest"

chmod +x "$dest"

