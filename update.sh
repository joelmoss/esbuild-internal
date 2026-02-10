#!/usr/bin/env bash
set -euo pipefail

version="$1"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-.+)?$ ]]; then
  echo "Error: invalid version" >&2
  exit 1
fi

echo "Downloading esbuild-${version}.tar.gz ..."

tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT

http_code=$(curl -s -o "$tmpfile" -w "%{http_code}" \
  "https://codeload.github.com/joelmoss/esbuild/tar.gz/refs/tags/v${version}")

if [[ "$http_code" != "200" ]]; then
  cat "$tmpfile" >&2
  exit 1
fi

# Clear non-hidden, non-images directories
for dir in */; do
  dir="${dir%/}"
  if [[ "$dir" != "images" ]]; then
    rm -rf "$dir"
  fi
done

# Extract to temp directory
tmpdir=$(mktemp -d)
trap 'rm -f "$tmpfile"; rm -rf "$tmpdir"' EXIT

tar xzf "$tmpfile" -C "$tmpdir"

srcdir="$tmpdir/esbuild-${version}"

# Process extracted files
find "$srcdir" -type f | while IFS= read -r filepath; do
  # Path relative to the esbuild source root
  filename="${filepath#"$srcdir/"}"

  if [[ "$filename" == internal/* ]]; then
    # Skip internal/cli_helpers/
    if [[ "$filename" == internal/cli_helpers/* ]]; then
      continue
    fi
    # Strip internal/ prefix
    target="${filename#internal/}"
    mkdir -p "$(dirname "$target")"
    sed 's|github.com/joelmoss/esbuild/internal|github.com/joelmoss/esbuild-internal|g' \
      "$filepath" > "$target"
    echo "write $filename"

  elif [[ "$filename" == pkg/api/* ]]; then
    # Skip test files
    if [[ "$filename" == *_test.go ]]; then
      continue
    fi
    # Strip pkg/ prefix
    target="${filename#pkg/}"
    mkdir -p "$(dirname "$target")"
    sed 's|github.com/joelmoss/esbuild/internal|github.com/joelmoss/esbuild-internal|g' \
      "$filepath" > "$target"
    echo "write $filename"

  elif [[ "$filename" == "go.mod" ]]; then
    sed 's|github.com/joelmoss/esbuild|github.com/joelmoss/esbuild-internal|g' \
      "$filepath" > go.mod
    echo "write $filename"

  elif [[ "$filename" == "version.txt" || "$filename" == "CHANGELOG.md" || \
          "$filename" == CHANGELOG-20* || "$filename" == "LICENSE.md" || \
          "$filename" == "go.sum" ]]; then
    cp "$filepath" "$filename"
    echo "write $filename"
  fi
done

# Check for --dry-run
for arg in "$@"; do
  if [[ "$arg" == "--dry-run" ]]; then
    exit 0
  fi
done

# Git operations
# git add --all .
# git commit -m "v${version}"
# git push origin
# git tag "v${version}"
# git push origin --tags

echo "Updated to ${version}"
