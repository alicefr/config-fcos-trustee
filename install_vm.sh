#!/bin/bash

STREAM="stable"
IGNITION_FILE="config.ign"
IGNITION_CONFIG="$(pwd)/${IGNITION_FILE}"
IMAGE="${HOME}/.local/share/libvirt/images/fedora-coreos.qcow2"
VM_NAME="fcos-kbs"
VCPUS="2"
RAM_MB="2048"
STREAM="stable"
DISK_GB="10"

set -xe 

while getopts "k:" opt; do
  case $opt in
    k) key=$OPTARG ;;
    \?) echo "Invalid option"; exit 1 ;;
  esac
done

if [ -z "${key}" ]; then
	echo "Please, specify the public ssh key"
	exit 1
fi


if [ ! -e  "${IMAGE}" ] ; then
	image=$(podman run --pull=newer --rm -v "${HOME}/.local/share/libvirt/images/":/data -w /data \
		quay.io/coreos/coreos-installer:release download -s $STREAM -p qemu -f qcow2.xz --decompress)
	mv "${HOME}/.local/share/libvirt/images/$image" $IMAGE
fi
bufile=$(mktemp)
sed "s|<KEY>|$key|g" config.bu &>${bufile}

podman run --interactive --rm --security-opt label=disable \
	--volume "$(pwd)":/pwd -v "${bufile}":/config.bu:z --workdir /pwd quay.io/coreos/butane:release \
	--pretty --strict /config.bu --output "/pwd/${IGNITION_FILE}" \
	--files-dir files

IGNITION_DEVICE_ARG=(--qemu-commandline="-fw_cfg name=opt/com.coreos/config,file=${IGNITION_CONFIG}")

chcon --verbose --type svirt_home_t ${IGNITION_CONFIG}

virsh destroy ${VM_NAME} || true
virsh undefine ${VM_NAME} --nvram --managed-save || true
virt-install --name="${VM_NAME}" --vcpus="${VCPUS}" --memory="${RAM_MB}" \
	--os-variant="fedora-coreos-$STREAM" --import --graphics=none \
	--disk="size=${DISK_GB},backing_store=${IMAGE}" \
	--network passt,portForward=2222:22 \
	--noautoconsole \
	--boot loader=/usr/share/edk2/ovmf/OVMF_CODE.fd,loader.readonly=yes,loader.type=pflash,nvram.template=/usr/share/edk2/ovmf/OVMF_VARS.fd  \
	--tpm backend.type=emulator,backend.version=2.0,model=tpm-tis \
	"${IGNITION_DEVICE_ARG[@]}"
