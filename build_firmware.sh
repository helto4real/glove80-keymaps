
#!/bin/bash

set -euo pipefail

./rake

# build the keymap file from the output from the rake task and the keymap template

# Input files
template_file="./firmware/keymap.template.zmk"
device_tree_file="device.dtsi"
custom_behaviors_file="keymap.dtsi"
output_file="./firmware/config/glove80.keymap"

# Create temporary files to hold substitution content
tmp_device_tree=$(mktemp)
tmp_custom_behaviors=$(mktemp)

# Write the content of the input files to temporary files
cat "$device_tree_file" > "$tmp_device_tree"
cat "$custom_behaviors_file" > "$tmp_custom_behaviors"

# Use sed with the temporary files to perform substitutions
sed -e "/@@DEVICE_TREE@@/{
    r $tmp_device_tree
    d
}" -e "/@@CUSTOM_BEHAVIORS@@/{
    r $tmp_custom_behaviors
    d
}" "$template_file" > "$output_file"

# Clean up temporary files
rm -f "$tmp_device_tree" "$tmp_custom_behaviors"

echo "File '$output_file' created successfully."


cp -f ./keymap.json ./firmware/config/
# cp -f ./keymap.zmk ./config/glove80.keymap

IMAGE=glove80-zmk-config-docker
BRANCH="${1:-main}"

docker build -f ./firmware/Dockerfile -t "$IMAGE" .
docker run --rm -v "$PWD:/firmware" -e UID="$(id -u)" -e GID="$(id -g)" -e BRANCH="$BRANCH" "$IMAGE"

# move the output firmware to firmware directory

mv -f ./glove80.uf2 ./firmware/
