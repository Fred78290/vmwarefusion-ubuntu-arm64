#!/bin/bash
set -e

source common.sh

ROOT_NAME=$1
VMDK_URL=$(echo "https://cloud-images.ubuntu.com/$(echo $ROOT_NAME | cut -d '-' -f 1)/current/$(echo $ROOT_NAME | cut -d '/' -f 1).img")
BASENAME=$(basename $ROOT_NAME)

if [ ! -f ${ROOT_NAME}.vmdk ]; then
    curl -s ${VMDK_URL} > ${ROOT_NAME}.img
    qemu-img convert ${ROOT_NAME}.img -O vmdk ${ROOT_NAME}.vmdk
    rm -f ${ROOT_NAME}.img
fi

SIZE_VMDK=$(stat ${ROOT_NAME}.vmdk | cut -d ' ' -f 8)

sed -i s/ovf:size=.*\ /ovf:size=\"$SIZE_VMDK\"\ / ${ROOT_NAME}.ovf

SHA_OVF=$(sha256sum ${ROOT_NAME}.ovf | cut -d ' ' -f 1)
SHA_VMDK=$(sha256sum ${ROOT_NAME}.vmdk | cut -d ' ' -f 1)

cat > ${ROOT_NAME}.mf <<EOF
SHA256(${BASENAME}.vmdk)= ${SHA_VMDK}
SHA256(${BASENAME}.ovf)= ${SHA_OVF}
EOF

ovftool --overwrite ${ROOT_NAME}.ovf ${ROOT_NAME}.ova