
#!/bin/bash

set -euo pipefail

./rake

# build the keymap file from the output from the rake task and the keymap template

# Input files
template_file="./firmware/keymap.template.zmk"
device_tree_file="device.dtsi"
custom_behaviors_file="keymap.dtsi"
output_file="./firmware/config/glove80.keymap"

sed -e '/\/\* Custom Device-tree \*\//,/\/\* Glove80 system behavior & macros \*\// {
    /\/\* Custom Device-tree \*\// {
        p
        r device.dtsi
    }
    /\/\* Glove80 system behavior & macros \*\//p
    d
}' -e '/\/\* Custom Defined Behaviors \*\//,/\/\* Automatically generated macro definitions \*\// {
    /\/\* Custom Defined Behaviors \*\// {
        p
        a\
/ {
        r keymap.dtsi
        a\
};
    }
    /\/\* Automatically generated macro definitions \*\//p
    d
}' keymap.zmk > $output_file

echo "File '$output_file' created successfully."


cp -f ./keymap.json ./firmware/config/
# cp -f ./keymap.zmk ./config/glove80.keymap

IMAGE=glove80-zmk-config-docker
BRANCH="${1:-main}"

docker build -f ./firmware/Dockerfile -t "$IMAGE" .
docker run --rm -v "$PWD:/firmware" -e UID="$(id -u)" -e GID="$(id -g)" -e BRANCH="$BRANCH" "$IMAGE"

# move the output firmware to firmware directory

mv -f ./glove80.uf2 ./firmware/
