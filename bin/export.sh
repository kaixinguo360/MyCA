#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

## 初始化安装参数 ##

# 设置静态参数
CA_ROOT=$(realpath $(dirname $0)/..)
CA_DATA=$CA_ROOT/data

# 读取输入参数
if [[ $1 = "-h" || $1 = "--help" || $1 = "" ]];then
  echo -e "用法: $0 [-n|--name Name] [-k|--key Key Path] [-c|--crt Crt Path]"
  echo -e "\t-n --name      主机名称"
  echo -e "\t-a --ca        导出CA证书"
  echo -e "\t-c --crt       导出证书"
  echo -e "\t-k --key       导出私钥"
  echo -e "\t-p --pkcs12    导出PKCS12证书文件"
  echo -e "\t-i --passin    输入密码"
  echo -e "\t-o --passout   输出密码"
  exit 0
fi

TEMP=`getopt -o n:k:c:p:i:o:a: --long name:,key:,crt:,pkcs12:,passin:,passout:,ca: \
     -n "$0" -- "$@"`
if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi
eval set -- "$TEMP"

while true ; do
    case "$1" in
        -n|--name)
            CommonName=$2
            FileName=$(echo "$CommonName"|sed 's/\*/_/g')
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
        -p|--pkcs12)
            PKCS12_PATH=$(readlink -f $2)
            shift 2
            ;;
        -i|--passin)
            PASS_IN=$2
            shift 2
            ;;
        -o|--passout)
            PASS_OUT=$2
            shift 2
            ;;
        -a|--ca)
            CA_PATH=$(readlink -f $2)
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

cd ${CA_DATA}
CERT_HOME="mycerts/${FileName}"
CRT_LOCATION="${CERT_HOME}/${FileName}.crt"
KEY_LOCATION="${CERT_HOME}/${FileName}.key"

## 正式导出开始 ##


# 导出CA证书
if [ -n "${CA_PATH}" ];then
    mkdir -p $(dirname ${CA_PATH}) > /dev/null
    cp cacert.pem ${CA_PATH}
    echo "已将CA证书导出到${CA_PATH}"
fi


# 导出证书
if [ -n "${CRT_PATH}" ];then
    if [ -e ${CRT_LOCATION} ];then
        CRT=$(< ${CRT_LOCATION})
        if [ -z "$CRT" ];then
            echo "${CommonName}证书不合法！"
            exit 1
        fi
    else
        echo "无法找到${CommonName}证书！它可能不存在或您没有读取权限"
        exit 1
    fi

    mkdir -p $(dirname ${CRT_PATH}) > /dev/null
    cp ${CRT_LOCATION} ${CRT_PATH}
    echo "已将 ${CommonName} 的证书导出到${CRT_PATH}"
fi


# 导出密钥
if [ -n "${KEY_PATH}" ];then
    if [ -e ${KEY_LOCATION} ];then
        CRT=$(< ${KEY_LOCATION})
        if [ -z "$CRT" ];then
            echo "${CommonName}密钥不合法！"
            exit 1
        fi
    else
        echo "无法找到${CommonName}密钥！它可能不存在或您没有读取权限"
        exit 1
    fi

    mkdir -p $(dirname ${KEY_PATH}) > /dev/null
    cp ${KEY_LOCATION} ${KEY_PATH}
    echo "已将 ${CommonName} 的密钥导出到${KEY_PATH}"
fi


# 导出PKCS12证书文件
if [ -n "${PKCS12_PATH}" ];then
    if [ -e ${CRT_LOCATION} ];then
        CRT=$(< ${CRT_LOCATION})
        if [ -z "$CRT" ];then
            echo "${CommonName}证书不合法！"
            exit 1
        fi
    else
        echo "无法找到${CommonName}证书！它可能不存在或您没有读取权限"
        exit 1
    fi
    
    if [ -e ${KEY_LOCATION} ];then
        CRT=$(< ${KEY_LOCATION})
        if [ -z "$CRT" ];then
            echo "${CommonName}密钥不合法！"
            exit 1
        fi
    else
        echo "无法找到${CommonName}密钥！它可能不存在或您没有读取权限"
        exit 1
    fi
    
    if [ -d ${PKCS12_PATH} ];then
        PKCS12_PATH=${PKCS12_PATH}/client.p12
    else
        mkdir -p $(dirname ${PKCS12_PATH}) > /dev/null
    fi
    openssl pkcs12 -export -clcerts -passin pass:"${PASS_IN}" -passout pass:"${PASS_OUT}" -in ${CRT_LOCATION} -inkey ${KEY_LOCATION} -out ${PKCS12_PATH}
    echo "已将 ${CommonName} 的PKCS12证书导出到${PKCS12_PATH}"
fi

