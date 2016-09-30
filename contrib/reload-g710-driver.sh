#!/bin/bash
#set -x
declare -r HID_PATH="/sys/bus/hid"
declare -r HID_DEVS_PATH="${HID_PATH}/devices"
declare -r HID_DRIVERS_PATH="${HID_PATH}/drivers"
declare -r HID_G710_PATH="${HID_DRIVERS_PATH}/hid-lg-g710-plus"
declare -r HID_G710_UNBIND_PATH="${HID_G710_PATH}/unbind"
declare -r G710_DEV_NAME_REGEX="^0003:046D:C24D\.[A-F0-9]{4}$"

echo -n 1 > ${HID_PATH}/drivers_autoprobe

declare -a HID_DEVS=($(ls -1bdU /sys/bus/hid/devices/*))
for DEV_PATH in ${HID_DEVS[@]} 
do
  DEV_NAME=$(basename ${DEV_PATH})
  DEV_DRIVER=$(readlink -e "${DEV_PATH}/driver")
  (
    [[ "${DEV_DRIVER}" == "${HID_G710_PATH}" ]] || [[ ${DEV_NAME} =~ ${G710_DEV_NAME_REGEX} ]]
  ) && (
    echo -n "${DEV_NAME}" > "${HID_G710_UNBIND_PATH}"
  )
done

modprobe -rf hid-lg-g710-plus
depmod -a
modprobe hid-lg-g710-plus
touch /sys/bus/hid/drivers_probe
exit 0
