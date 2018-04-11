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
OPENSSL_CONF='/usr/lib/ssl/openssl.cnf'
OPENSSL_CONF_URL='https://raw.githubusercontent.com/kaixinguo360/MyCA/master/openssl.cnf'


# 读取输入参数
if [[ $1 = "-h" || $1 = "--help" || $1 = "" ]];then
  echo "用法: $0 [-p Password -n Name -e EmailAddress -f]"
  echo -e "\t-p 密码"
  echo -e "\t-n 主机名称"
  echo -e "\t-e 邮箱"
  echo -e "\t-f 强制重新签署证书"
  exit 0
fi

while getopts "p:n:e:f" arg #选项后面的冒号表示该选项需要参数
do
    case $arg in
        p)
           Password=$OPTARG
           ;;
        n)
           CommonName=$OPTARG
           ;;
        e)
           EmailAddress=$OPTARG
           ;;
        f)
           FORCE='y'
           ;;
        ?)  #当有不认识的选项的时候arg为?
           echo "未知选项"
           exit 1
           ;;
    esac
done

#if [ -z "${Password}" ];then
#  echo "非法密码"
#  exit 1
#fi

CA_ROOT=$(dirname $(readlink -f $0))


## 正式安装开始 ##


# 生成证书保存目录
cd ${CA_ROOT}
mkdir -p mycerts/${CommonName} > /dev/null
cd mycerts/${CommonName}

# 检查是否已经生成证书
if [[ ! "$FORCE" = 'y' && -e ${CommonName}.crt ]];then
    CRT=$(< ${CommonName}.crt)
    if [ -n "$CRT" ];then
        echo -e "\n  ## \033[32m证书\033[0m \033[34m${CommonName}\033[0m \033[32m已存在\033[0m ##\n"
        exit 0
    fi
fi


## OpenSSL操作 ##

# 生成私钥
if [ -n "$Password" ];then
    openssl genrsa -aes256 -passout pass:$Password -out ${CommonName}.key 2048
else
    openssl genrsa -out ${CommonName}.key 2048
fi


# 创建证书请求
openssl req -new -passin pass:"$Password" \
        -key ${CommonName}.key \
        -out ${CommonName}.csr \
        -subj "/C=CN/ST=Beijing/L=Beijing/O=${CommonName}/CN=${CommonName}/emailAddress=${EmailAddress}/" \
        #-reqexts SAN \
        -config <(cat /usr/lib/ssl/openssl.cnf \
            <(printf "[ alt_names ]\DNS.1 = ${CommonName}"))
        
# 上面-subj选项中几个字段的意义
# C  => Country
# ST => State
# L  => City
# O  => Organization
# OU => Organization Unit
# CN => Common Name (证书所请求的域名)
# emailAddress => main administrative point of contact for the certificate


# 签署证书
CA_PW=$(< ${CA_ROOT}/private/passwd)
openssl ca -batch -passin pass:"$CA_PW" -in ${CommonName}.csr -out ${CommonName}.crt


# 验证是否签名成功,否则删除临时文件
if [ ! -e ${CommonName}.crt ];then
    IS_SUCCESS="n"
else
    CRT=$(< ${CommonName}.crt)
    if [ -z "$CRT" ];then
        IS_SUCCESS="n"
    fi
fi

if [ "${IS_SUCCESS}" = "n" ];then
    cd ..
    rm -rf ${CommonName}
    echo -e "\n  ## \033[31m证书\033[0m \033[34m${CommonName}\033[0m \033[31m签名失败\033[0m ##\n"
    exit 404
else
    echo -e "\n  ## \033[32m证书\033[0m \033[34m${CommonName}\033[0m \033[32m签名成功\033[0m ##\n"
    exit 0
fi
