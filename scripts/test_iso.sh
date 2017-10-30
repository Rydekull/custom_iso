#!/bin/bash
VMNAME=${1:-test.example.com}
virsh destroy ${VMNAME} ; virsh undefine ${VMNAME}
rm -rf /var/lib/libvirt/images/${VMNAME}.qcow2
cp ../custom_inst.iso /var/lib/libvirt/images/custom_inst.iso
cd ../custom_inst
sed -i "/^network/s/hostname=.*/hostname=${VMNAME}/g" ks.cfg
qemu-img create -f qcow2 /var/lib/libvirt/images/${VMNAME}.qcow2 50g
virt-install --name ${VMNAME} --vcpus 1 --memory 1024 --disk /var/lib/libvirt/images/${VMNAME}.qcow2 --network network=default --network network=secondary -l /var/lib/libvirt/images/custom_inst.iso --initrd-inject=ks.cfg --extra-args "ks=file:/ks.cfg"
#"ks=hd:LABEL=CUSTOM_INST:/ks.cfg"
