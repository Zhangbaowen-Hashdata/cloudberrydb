#!/bin/bash

source concourse/scripts/README.CentOS.bash

sudo yum -y install R apr apr-devel apr-util automake autoconf bash bison bison-devel bzip2 bzip2-devel centos-release-scl curl flex flex-devel gcc gcc-c++ git gdb iproute krb5-devel less libcurl libcurl-devel libevent libevent-devel libxml2 libxml2-devel libyaml libzstd-devel libzstd make openldap openssh openssh-clients openssh-server openssl openssl-devel openssl-libs perl python3-devel readline readline-devel rsync sed sudo tar vim wget which xerces-c-devel zip zlib

sudo yum -y install epel-release

sudo yum install -y centos-release-scl
sudo yum -y install devtoolset-10-gcc devtoolset-10-gcc-c++ devtoolset-10-binutils
#scl enable devtoolset-10 bash
source /opt/rh/devtoolset-10/enable
sudo gcc -v
ls -l /etc/bashrc
sudo chmod 777 /etc/bashrc
sudo echo "source /opt/rh/devtoolset-10/enable" >> /etc/bashrc
source /etc/bashrc
sudo chmod 644 /etc/bashrc
sudo ln -sf /usr/bin/cmake3 /usr/local/bin/cmake

ls -l /etc/ld.so.conf
sudo chmod 777 /etc/ld.so.conf
sudo echo -e "/usr/local/lib \n/usr/local/lib64" >> /etc/ld.so.conf
sudo ldconfig
echo "环境搭建完成"