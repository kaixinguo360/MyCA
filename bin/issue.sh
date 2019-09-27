#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

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
CA_ROOT=$(realpath $(dirname $0)/..)
CA_DATA="$CA_ROOT/data"
CA_CONF="$CA_ROOT/openssl.cnf"

# 检查是否已初始化
[[ ! -d "${CA_DATA}/private" ]] && { echo "找不到CA根证书! 是否未初始化?"; exit 1; }

# 检查是否有操作权限
[[ -d "${CA_DATA}/private" && ! -r "${CA_DATA}/private" ]] && { echo "Error: Permission denied. Please make sure you have the correct access rights"; exit 1; }

# 设置默认参数
EmailAddress=${USER}@$(cat /etc/mailname||echo $HOSTNAME)
Days=365


# 读取输入参数
if [[ $1 = "-h" || $1 = "--help" || $1 = "" ]];then
  echo "用法: $0 [-n Name] [-p Password] [-e EmailAddress] [-d Days] [-w] [-f]"
  echo -e "\t-n 主机名称(必须)"
  echo -e "\t-p 密码(默认无密码)"
  echo -e "\t-e 邮箱(默认'${EmailAddress}')"
  echo -e "\t-d 证书有效期(天)(默认${Days})"
  echo -e "\t-w 支持泛域名"
  echo -e "\t-f 强制重新签署证书"
  exit 0
fi

while getopts "p:n:e:d:wf" arg #选项后面的冒号表示该选项需要参数
do
    case $arg in
        n)
           CommonName=$OPTARG
           FileName=$(echo "$CommonName"|sed 's/\*/_/g')
           ;;
        p)
           Password=$OPTARG
           ;;
        e)
           EmailAddress=$OPTARG
           ;;
        d)
           Days=$OPTARG
           ;;
        w)
           Wildcard='y'
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


## 正式安装开始 ##


# 生成证书保存目录
cd ${CA_DATA}
mkdir -p mycerts/${FileName} > /dev/null
cd mycerts/${FileName}

# 检查是否已经生成证书
if [[ ! "$FORCE" = 'y' && -e ${FileName}.crt ]];then
    CRT=$(< ${FileName}.crt)
    if [ -n "$CRT" ];then
        echo -e "\n  ## \033[32m证书\033[0m \033[34m${CommonName}\033[0m \033[32m已存在\033[0m ##\n"
        exit 0
    fi
fi


## OpenSSL操作 ##

# 生成私钥
if [ -n "$Password" ];then
    openssl genrsa -aes256 -passout pass:$Password -out ${FileName}.key 2048
else
    openssl genrsa -out ${FileName}.key 2048
fi

# 设置替代名称
SubjectAltName="DNS:${CommonName}"
if [ -n "$Wildcard" ];then
    SubjectAltName="${SubjectAltName},DNS:*.${CommonName}"
fi

# 创建证书请求
openssl req -new -passin pass:"$Password" \
        -key ${FileName}.key \
        -out ${FileName}.csr \
        -days ${Days} \
        -subj "/C=CN/ST=Beijing/L=Beijing/O=${CommonName}/CN=${CommonName}/emailAddress=${EmailAddress}/" \
        -reqexts SAN \
        -config <(cat "${CA_CONF}" \
            <(printf "[SAN]\nsubjectAltName=${SubjectAltName}")|sed "s#TMP_CA_DATA#${CA_DATA}#g")
        
# 上面-subj选项中几个字段的意义
# C  => Country
# ST => State
# L  => City
# O  => Organization
# OU => Organization Unit
# CN => Common Name (证书所请求的域名)
# emailAddress => main administrative point of contact for the certificate

# 签署证书
CA_PW=$(< ${CA_DATA}/private/passwd)
openssl ca -batch -passin pass:"$CA_PW" \
        -in ${FileName}.csr \
        -out ${FileName}.crt \
        -days ${Days} \
        -extensions SAN \
        -config <(cat "${CA_CONF}" \
            <(printf "[SAN]\nsubjectAltName=${SubjectAltName}")|sed "s#TMP_CA_DATA#${CA_DATA}#g")

# 清空index.txt文件
rm ${CA_DATA}/index.txt
touch ${CA_DATA}/index.txt

# 清空newcerts文件夹
rm -f ${CA_DATA}/newcerts/*

# 验证是否签名成功,否则删除临时文件
if [ ! -e ${FileName}.crt ];then
    IS_SUCCESS="n"
else
    CRT=$(< ${FileName}.crt)
    if [ -z "$CRT" ];then
        IS_SUCCESS="n"
    fi
fi

if [ "${IS_SUCCESS}" = "n" ];then
    cd ..
    rm -rf ${FileName}
    echo -e "\n  ## \033[31m证书\033[0m \033[34m${CommonName}\033[0m \033[31m签名失败\033[0m ##\n"
    exit 404
else
    echo -e "\n  ## \033[32m证书\033[0m \033[34m${CommonName}\033[0m \033[32m签名成功\033[0m ##\n"
    exit 0
fi
