#!/bin/bash -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SRC_DIR="$HOME/.local/share/ov/pkg/connectsample-203.1.0/_build/linux-x86_64/release"
DEST_DIR="$DIR/../../thirdparty/omnicli/"
if [ ! -d "$SRC_DIR" ]; then
  echo "Error: '$SRC_DIR' does not exist."
  echo "Please make sure that Connect Sample 203.1.0 is installed through Omniverse Launcher."
  exit 1
fi
echo "Copying omnicli and its dependencies to '$DEST_DIR'..."
mkdir -p "$DEST_DIR"
cp "$SRC_DIR/omnicli" "$DEST_DIR"
cat "$DIR/omnicli-deps.txt" | xargs -I {} cp "$SRC_DIR/{}" "$DEST_DIR"
echo "Done."
