#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# 检查是否为Root
[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }

# 检查系统信息
if [ ! -z "`cat /etc/issue | grep 'Ubuntu 16'`" ];
    then
        OS='Ubuntu'
    else
        echo "Not support OS(Ubuntu 16), Please reinstall OS and retry!"
        #exit 1
fi

PATH=$1
if [ -z "$PATH" ];then
    PATH=$(pwd)/cacert.pem
fi

CA_ROOT=$(dirname $(readlink -f $0))
cd ${CA_ROOT}

openssl rsa -in ${CA_ROOT}/cacert.pem -out ${PATH}

