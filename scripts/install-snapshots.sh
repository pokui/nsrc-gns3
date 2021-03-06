#!/bin/bash -eu

GNS3FILE="$1"

if [ ! -f "$GNS3FILE" ]; then
  echo "Unable to find $GNSFILE"
  exit 1
fi
dir="$(dirname "$GNS3FILE")"
mkdir -p "$dir"/snapshots
rm -f "$dir"/snapshots/*
cp -p snapshots/* "$dir"/snapshots/
