#!/bin/bash
set -eux
A=/autodl-fs/data/artifacts/robocasa365/data/assets
D=$A/_downloads
mkdir -p "$A/objects" "$A/fixtures" "$A/objects/lightwheel"

unzip -q -o "$D/textures.zip" -d "$A"
unzip -q -o "$D/generative_textures.zip" -d "$A"
unzip -q -o "$D/objaverse.zip" -d "$A/objects"
unzip -q -o "$D/aigen_objs.zip" -d "$A/objects"

find "$A/_downloads_lw/fixtures_lightwheel" -name "*.zip" -exec unzip -q -o {} -d "$A/fixtures" \;
find "$A/_downloads_lw/objects_lightwheel" -name "*.zip" -exec unzip -q -o {} -d "$A/objects/lightwheel" \;

echo UNPACK_DONE
