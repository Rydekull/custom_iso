#!/bin/bash
DIST=${1}

function usage()
{
  echo Specify if you want to create a RHEL or Fedora ISO
  echo Example:
  echo   $(basename $0) fedora
  echo
  echo Please note, if you want to build a RHEL iso you need to supply username/password/subscription pool ID.
  exit 1
}

if [ "${DIST}" = "" ]
then
  usage
fi

if [ "${DIST}" = "rhel" ]
then
  CA=/etc/rhsm/ca/redhat-uep.pem
  KEY=$(ls /etc/pki/entitlement/*-key.pem | head -n 1)
  CERT=$(echo $KEY | sed 's/-key//g')
  RH_ISO_URL=https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/iso
  REPOS="rhel-7-server-extras-rpms rhel-7-fast-datapath-rpms rhel-7-server-ose-3.6-rpms"
  ISO_HOSTNAME=${1:-testiso.example.com}

  ISO=$(curl -s --cacert ${CA} --cert ${CERT} --key ${KEY} ${RH_ISO_URL} | awk '$0 ~ /rhel-server/ && $0 ~ /dvd\.iso/ {gsub(/ *<[^>]*> */," ");print }' | sort -t- -k 2,2n -k 3 | awk 'END{ print $1 }')

  if [ ! -f "../${ISO}" ]
  then
    curl --cacert ${CA} --cert ${CERT} --key ${KEY} ${RH_ISO_URL}/${ISO} -o ../${ISO}
  fi

  yum install https://ftp.acc.umu.se/mirror/fedora/epel/7/x86_64/e/epel-release-7-10.noarch.rpm -y
elif [ "${DIST}" = "fedora" ]
then
  FLAVOR=Server
  RELEASE=26
#  ISO_URL=https://ftp.acc.umu.se/mirror/fedora/linux/releases/${RELEASE}/${FLAVOR}/x86_64/iso/Fedora-${FLAVOR}-Live-x86_64-${RELEASE}-1.5.iso
  ISO_URL=https://gensho.ftp.acc.umu.se/mirror/fedora/linux/releases/${RELEASE}/${FLAVOR}/x86_64/iso/Fedora-${FLAVOR}-dvd-x86_64-${RELEASE}-1.5.iso
  ISO=fedora-${RELEASE}-${FLAVOR}.iso
  if [ ! -f "../${ISO}" ]
  then
    curl ${ISO_URL} -o ../${ISO}
  fi
else
  usage
fi

yum install p7zip xorriso syslinux createrepo -y

if [ ! -d ../custom_inst ]
then
  xorriso -osirrox on -indev ../${ISO} extract / ../custom_inst
fi

if [ "${DIST}" = "rhel" ]
then
  for REPO in $REPOS
  do
    reposync -n -r $REPO -p ../custom_inst/rpms
    cat <<EOF> ../custom_inst/rpms/${REPO}.repo
[${REPO}]
metadata_expire = 86400
baseurl = file:///srv/rpms/${REPO}
ui_repoid_vars = releasever basearch
sslverify = 1
name = ${REPO}
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-beta,file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
enabled = 1
sslcacert = /etc/rhsm/ca/redhat-uep.pem
gpgcheck = 1
EOF
    createrepo ../custom_inst/rpms/$REPO
  done
fi

cp -r ../files/${DIST}/* ../custom_inst/

cd ../custom_inst
sed -i "/^network/s/hostname=.*/hostname=${ISO_HOSTNAME}/g" ks.cfg
xorriso -as mkisofs -o ../custom_inst.iso -isohybrid-mbr /usr/share/syslinux/isohdpfx.bin -c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table -V CUSTOM_INST ./
#lsblk -o NAME,TRAN | awk '$NF ~ /^usb$/ { print $1 }'
