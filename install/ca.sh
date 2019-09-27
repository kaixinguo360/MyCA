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

CA_ROOT=$(realpath $(dirname $0)/..)
CA_DATA=$CA_ROOT/data


# 读取输入参数
if [[ $1 = "-h" || $1 = "--help" || $1 = "" ]];then
  echo "用法: $0 Password CommonName EmailAddress"
  exit 0
fi

CA_PW=$1
CommonName=$2
EmailAddress=$3


## 正式安装开始 ##

# 创建CA文件夹结构
mkdir -p ${CA_DATA}
cd ${CA_DATA}
mkdir newcerts certs crl private requests
touch index.txt
echo '01' > serial

# 下载配置文件
wget -O ${OPENSSL_CONF} ${OPENSSL_CONF_URL} -nv
sed -i "s#TMP_CA_DATA#${CA_DATA}#g" ${OPENSSL_CONF}

# 生成生成根私钥
expect << HERE
    set timeout -1
    
    spawn openssl genrsa -aes256 -out private/cakey.pem 4096
    
    expect "*Enter pass phrase for*"
    send "$CA_PW\r"
    
    expect "*Verifying*"
    send "$CA_PW\r"
    
    expect eof
HERE

# 创建根证书
expect << HERE
    set timeout -1
    
    spawn openssl req -new -x509 -key private/cakey.pem -out cacert.pem -days 3650 -set_serial 0
    
    expect "*Enter pass phrase for*"
    send "$CA_PW\r"
    
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
    
    expect eof
HERE

# 修改权限
chmod -R 600 private


## 安装完成 ##
