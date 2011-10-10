#!/bin/bash
set -e
set -o physical

ORIG_TARBALL="$1"
shift || true
NAME=$(basename "$ORIG_TARBALL")
TMP_DEST=$(mktemp -d)
TARBALL="$TMP_DEST/stripped-${NAME}"
repack() {
	local here="$TMP_DEST/repack"
	mkdir -p "$here"
	tar xapf "$ORIG_TARBALL" -C "$here" &>/dev/null
	find "$here"/ -not -type l -exec touch {} \; || true
	find "$here"/ -not -type l -exec chown 0.0 {} \; || true
	cd "$here"/*
	tar cpf "$TARBALL" *
	rm -rf "$here"
}

extract_modules() {
	tar xapf "$TARBALL" --overwrite --exclude=*/firmware* --exclude=*/usr* --exclude=*/boot* -C "$DEST"
}
extract_firmware() {
	tar xapf "$TARBALL" --keep-old-files --exclude=*/modules* --exclude=*/usr* --exclude=*/boot* -C "$DEST"
}
extract_kernel() {
	tar xapf "$TARBALL" --keep-old-files --exclude=*/lib* --exclude=*/usr* -C "$DEST"
}
extract_boot() {
	tar xapf "$TARBALL" --keep-old-files --exclude=*/lib* --exclude=*/usr* -C "$DEST"
}
extract_headers() {
	tar xapf "$TARBALL" --keep-old-files --exclude=*/lib* --exclude=*/boot* -C "$DEST"
}
extract_usr() {
	tar xapf "$TARBALL" --overwrite --exclude=*/lib* --exclude=*/boot* -C "$DEST"
#	tar xapf "$TARBALL" --keep-old-files --exclude=*/lib* --exclude=*/boot* -C "$DEST"
}

if ! [[ -f "$ORIG_TARBALL" ]]; then
	echo "??"
	exit 1
fi
repack || exit $?

DEST="${DEST:-}"
#if [[ "$DEST" =~ ^/*$ ]]; then
if [[ -z "$DEST" ]]; then
#	echo "please define DEST with DEST != /."
	echo "DEST?"
	exit 11
fi

for this in $*; do
	extract_$this
done

rm -rf "$TMP_DEST"
