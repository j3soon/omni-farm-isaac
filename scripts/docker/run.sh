#!/bin/bash -e

show_help() {
  echo -e "\nUsage: $0 [OPTIONS] <command>\n"
  echo "Options:"
  echo "  --download-src    The source file or folder to download"
  echo "  --download-dest   The destination file or folder to download to"
  echo "  --upload-src      The source file or folder to upload"
  echo "  --upload-dest     The destination file or folder to upload to"
  echo -e "\nThis script downloads the necessary files, executes the specified command, and then uploads the output files.\n"
}

resolve_path() {
  local path="$1"
  if [[ "$path" != "omniverse://"* && ! "$path" == /* ]]; then
    path="$(pwd)/$path"
  fi
  echo "$path"
}

# Ref: https://stackoverflow.com/a/14203146
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --download-src)
      DOWNLOAD_SRC=$(resolve_path "$2")
      shift # past argument
      shift # past value
      ;;
    --download-dest)
      DOWNLOAD_DEST=$(resolve_path "$2")
      shift # past argument
      shift # past value
      ;;
    --upload-src)
      UPLOAD_SRC=$(resolve_path "$2")
      shift # past argument
      shift # past value
      ;;
    --upload-dest)
      UPLOAD_DEST=$(resolve_path "$2")
      shift # past argument
      shift # past value
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

if [ "$#" -ne 1 ]; then
  echo "Error: Incorrect number of arguments. Expected 1, got $#."
  show_help
  exit 1
fi

if [ -n "$DOWNLOAD_SRC" ] || [ -n "$DOWNLOAD_DEST" ]; then
  echo "Copying files from '$DOWNLOAD_SRC' to '$DOWNLOAD_DEST'..."
  ( cd /omnicli && ./omnicli copy "$DOWNLOAD_SRC" "$DOWNLOAD_DEST" )
fi

echo "Running command: '$1'"
$1

if [ -n "$UPLOAD_SRC" ] || [ -n "$UPLOAD_DEST" ]; then
  echo "Copying files from '$UPLOAD_SRC' to '$UPLOAD_DEST'..."
  ( cd /omnicli && ./omnicli copy "$UPLOAD_SRC" "$UPLOAD_DEST" )
fi
