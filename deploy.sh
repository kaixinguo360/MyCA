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


## 初始化安装参数 ##

# 设置静态参数
CA_ROOT=$(dirname $(readlink -f $0))

# 读取输入参数
if [[ $1 = "-h" || $1 = "--help" || $1 = "" ]];then
  echo "用法: $0 Password CommonName EmailAddress"
  exit 0
fi

TEMP=`getopt -o n:k:c: --long name:,key:,crt: \
     -n "$0" -- "$@"`
if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi
eval set -- "$TEMP"

while true ; do
        case "$1" in
                -n|--name)
                        CommonName=$2
                        shift 2
                        ;;
                -k|--key)
                        KEY_PATH=$2
                        shift 2
                        ;;
                -c|--crt)
                        CRT_PATH=$2
                        shift 2
                        ;;
                --)
                        shift
                        break
                        ;;
                *)
                        echo "Internal error!"
                        exit 1
                        ;;
        esac
done

# 非法参数
for arg do
   echo "非法参数'$arg'" ;
   exit 1
done

echo "Continue"















