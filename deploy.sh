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
  echo -e "用法: $0 [-n|--name Name] [-k|--key Key Path] [-c|--crt Crt Path]"
  echo -e "\t-n --name 主机名称"
  echo -e "\t-k --key 私钥路径"
  echo -e "\t-c --crt 公钥路径"
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
            KEY_PATH=$(readlink -f $2)
            shift 2
            ;;
        -c|--crt)
            CRT_PATH=$(readlink -f $2)
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

for arg do
   echo "非法参数'$arg'" ;
   exit 1
done

CA_ROOT=$(dirname $(readlink -f $0))

## 正式安装开始 ##

cd ${CA_ROOT}

# 验证证书目录存在
if [ ! -e mycerts/${CommonName} ];then
    echo "没有找到${CommonName}证书目录！"
    exit 1;
fi
cd mycerts/${CommonName}


# 复制证书
if [ -n "${CRT_PATH}" ];then
    if [ -e ${CommonName}.crt ];then
        CRT=$(< ${CommonName}.crt)
        if [ -z "$CRT" ];then
            echo "${CommonName}证书不合法！"
            exit 1
        fi
    else
        echo "${CommonName}证书不存在！"
        exit 1
    fi

    mkdir -p $(dirname ${CRT_PATH}) > /dev/null
    cp ${CommonName}.crt ${CRT_PATH}
    echo "已将 ${CommonName} 的证书复制到${CRT_PATH}"
fi

# 复制密钥
if [ -n "${KEY_PATH}" ];then
    if [ -e ${CommonName}.key ];then
        CRT=$(< ${CommonName}.key)
        if [ -z "$CRT" ];then
            echo "${CommonName}密钥不合法！"
            exit 1
        fi
    else
        echo "${CommonName}密钥不存在！"
        exit 1
    fi

    mkdir -p $(dirname ${KEY_PATH}) > /dev/null
    cp ${CommonName}.key ${KEY_PATH}
    echo "已将 ${CommonName} 的密钥复制到${KEY_PATH}"
fi
