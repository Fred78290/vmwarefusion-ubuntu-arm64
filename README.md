# vmwarefusion-ubuntu-arm64

Build OVA for ubuntu arm64 and run ubuntu VM on AppleSilicon with **VMWare fusion 13**


## Goal

This project is designed to create a VM machine with VMWare Fusion 13 on  AppleSilicon. It create also an OVA.

To do it

`
./create-vm-ubuntu-arm64.sh
`

## Requirement

Due some lack on native used command, you need to install homebrew

``
brew install gsed coreutils gnu-getopt
``


## Supported version

- ubuntu 20.04
    - Won't start on MacMini 2023 M2 pro
- ubuntu 22.04
    - Works well
- ubuntu 22.10
    - work without display, ssh use only

To se the desired version uncomment/comment SEED variable in script.
