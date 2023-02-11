#!/bin/bash
source common.sh

# Comment/uncomment the wanted ubuntu version

SEED=jammy-server-cloudimg-arm64/ubuntu-jammy-22.04-cloudimg
#SEED=focal-server-cloudimg-arm64/ubuntu-focal-20.04-cloudimg
#SEED=kinetic-server-cloudimg-arm64/ubuntu-kinetic-22.10-cloudimg

OVA="${SEED}.ova"
ISODIR=generated
SSH_KEY=$(cat $HOME/.ssh/id_rsa.pub)
TZ=$(sudo systemsetup -gettimezone | awk -F: '{print $2}' | tr -d ' ')
CACHE=$ISODIR
BASENAME=$(basename ${OVA})
NAME=${BASENAME:0:${#BASENAME}-4}
VMDIR="$HOME/Virtual Machines.localized"
VMX="${VMDIR}/${NAME}.vmwarevm/${NAME}.vmx"
INSTANCEID=$(uuidgen)
VMREST_URL=http://localhost:8697

mkdir -p "${VMDIR}"
rm -rf "$(dirname ${VMX})"

mkdir -p "${ISODIR}"
mkdir -p "${CACHE}"

if [ ! -f ${OVA} ]; then
    echo_title "Create OVA for ${SEED}"
    ./create-ova.sh "${SEED}"
fi

echo_title "Create vmx ${VMX}"

ovftool --overwrite --name=${NAME} --allowAllExtraConfig ${OVA} "${VMDIR}"

cat > "${ISODIR}/user-data" <<EOF
#cloud-config
EOF

cat > "${ISODIR}/network.yaml" <<EOF
#cloud-config
network:
    version: 2
    ethernets:
        eth0:
            dhcp4: true
EOF

cat > "${ISODIR}/vendor-data" <<EOF
#cloud-config
timezone: $TZ
ssh_authorized_keys:
    - $SSH_KEY
users:
    - default
system_info:
    default_user:
        name: ubuntu
EOF

cat > "${ISODIR}/meta-data" <<EOF
{
    "local-hostname": "ubuntuguest",
    "instance-id": "$INSTANCEID"
}
EOF

gzip -c9 < "${ISODIR}/meta-data" | base64 -w 0 > ${CACHE}/metadata.base64
gzip -c9 < "${ISODIR}/user-data" | base64 -w 0 > ${CACHE}/userdata.base64
gzip -c9 < "${ISODIR}/vendor-data" | base64 -w 0 > ${CACHE}/vendordata.base64

sed -i -e '/sata0:1/Id' \
    -e '/vmci0.unrestricted/Id' \
    -e '/toolscripts/Id' \
    -e '/cpuid.numSMT/Id' \
    -e '/guestinfo/Id' \
    -e '/guestos/Id' \
    -e '/vhv.enable/Id' \
    -e '/memsize/Id' \
    -e '/numvcpus/Id' \
    -e '/virtualHW.version/Id' "$VMX"

cat >> "$VMX" <<EOF
sata0:1.autodetect = "TRUE"
sata0:1.deviceType = "cdrom-raw"
sata0:1.fileName = "auto detect"
sata0:1.present = "TRUE"
sata0:1.startConnected = "FALSE"
ethernet0.linkStatePropagation.enable = "TRUE"
powerType.powerOn = "soft"
nvram = "$NAME.nvram"
extendedConfigFile = "$NAME.vmxf"
hpet0.present = "TRUE"
virtualHW.version = "20"
memsize = "3072"
numvcpus = "2"
guestos = "arm-ubuntu-64"
guestinfo.metadata = "$(cat ${CACHE}/metadata.base64)"
guestinfo.metadata.encoding = "gzip+base64"
guestinfo.userdata = "$(cat ${CACHE}/userdata.base64)"
guestinfo.userdata.encoding = "gzip+base64"
guestinfo.vendordata = "$(cat ${CACHE}/vendordata.base64)"
guestinfo.vendordata.encoding = "gzip+base64"
EOF

cat > "${CACHE}/body.json" <<EOF
{
    "name": "${NAME}",
    "path": "${VMX}"
}
EOF

if [ -z "$(ps x|grep vmrest|grep -v grep)" ]; then
    nohup vmrest > /dev/null &
elif [[ "$(curl -ks http://localhost:8697)" =~ "Client sent an HTTP request to an HTTPS server" ]]; then
    VMREST_URL=https://localhost:8697
fi

curl -L -k -u "${USER}:${GOVC_PASSWORD}" -XPOST -H 'Content-Type: application/vnd.vmware.vmw.rest-v1+json' ${VMREST_URL}/api/vms/registration -d @"${CACHE}/body.json"