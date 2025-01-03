# How to do local builds
This method allows you to build the firmware locally on your computer. Docker is required.
You will need to make a template file using your keymap file as reference. It require some work but
it lets you iterate fast building and testing new firmware versions.

See this as inspiration as a way to allow local builds, I did not spend much time refining this
for making it more easy for all users.

Follow the following steps below:

1. Make your customizations in the online keymap editor by first cloing the v40 version of Sunakus keymap.
2. Download and replace the `keymap.zmk` file
3. Download and replace the keymap.json file (you will have to set `enable local config` in settings) and use download button.
4. Use the `./firmware/keymap.template.zmk` as reference copy your specific keymap from the `keymap.zmk` in the bottom of the template file
5. Do any customizations to the `.erb` files as fit. You can make your customizations easier to rebase using external files as example in this repo
6. Run `./build_firmware.sh` to build the firmware. The resulting firmware will be in the `./firmware/` directory.

My version use the PR36 version of the firmware to allow per-key RGB control. If you want to use
master version, remove the `firmware/Dockerfile` and rename the `firmware/Dockerfile.old` to `Dockefile`.
If the master does not support the `CONFIG_EXPERIMENTAL_RGB_LAYER=y` flag you will have to remove it from
`firmware/config/glove80.conf` file.

