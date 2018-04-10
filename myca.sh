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
  echo "用法: $0 Password CommonName EmailAddress"
  exit 0
fi

Password=$1
CommonName=$2
EmailAddress=$3
CA_ROOT=$(dirname $(readlink -f $0))


## 正式安装开始 ##

# 生成证书保存目录
cd ${CA_ROOT}
mkdir -p mycerts/${CommonName} > /dev/null
cd mycerts/${CommonName}

# 检查是否已经生成证书
if [ -e ${CommonName}.crt ];then
    echo -e "\n  ## \033[32m证书已存在\033[0m ##\n"
    exit 0
fi

# 生成私钥
expect << HERE
    spawn openssl genrsa -aes256 -out ${CommonName}.key 2048
    
    expect "*Enter pass phrase for*"
    send "$Password\r"
    
    expect "*Verifying*"
    send "$Password\r"
    
    expect eof
HERE

# 创建证书请求
expect << HERE
    spawn openssl req -new -key ${CommonName}.key -out ${CommonName}.csr
    
    expect "*Enter pass phrase for*"
    send "$Password\r"
    
    expect "*Country Name*"
    send "\r"
    expect "*State or Province Name*"
    send "\r"
    expect "*Locality Name*"
    send "\r"
    expect "*Organization Name*"
    send "\r"
    expect "*Organizational Unit Name*"
    send "\r"
    expect "*Common Name*"
    send "$CommonName\r"
    expect "*Email Address*"
    send "$EmailAddress\r"
    
    expect "*A challenge password*"
    send "\r"
    expect "*An optional company name*"
    send "\r"
    
    expect eof
HERE


# 签署证书
CA_PW=$(< ${CA_ROOT}/private/passwd) 
expect << HERE
    spawn openssl ca -in ${CommonName}.csr -out ${CommonName}.crt
    
    expect "*Enter pass phrase for*"
    send "$CA_PW\r"
    
    expect "*Sign the certificate*"
    send "y\r"
    
    expect "*commit?*"
    send "y\r"
    
    expect eof
HERE

# 验证是否签名成功,否则删除临时文件
if [ ! -e ${CommonName}.crt ];then
    cd ..
    rm -rf ${CommonName}
    echo -e "\n  ## \033[31m证书签名失败\033[0m ##\n"
    exit 404
else
    echo -e "\n  ## \033[32m证书签名成功\033[0m ##\n"
    exit 0
fi
