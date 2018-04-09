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
if [ $1="-h" || $1="--help" || $1="" ];then
  echo "用法: $0 CA根目录"
  exit 0
fi

CA_ROOT=$1
if [ ! -e ${CA_ROOT} ];then
  echo "目录不存在!"
  exit 1
fi


## 正式安装开始 ##

# 创建CA文件夹结构
mkdir ${CA_ROOT}
cd ${CA_ROOT}
mkdir newcerts certs crl private requests
touch index.txt
echo '01' > serial

# 下载配置文件
wget -O ${OPENSSL_CONF} ${OPENSSL_CONF_URL} -nv
sed "s/TMP_CA_ROOT/${CA_ROOT}/g" ${OPENSSL_CONF}

# 生成生成根私钥
openssl genrsa -aes256 -out private/cakey.pem 4096

# 创建根证书
openssl req -new -x509 -key /root/ca/private/cakey.pem -out cacert.pem -days 3650 -set_serial 0


## 安装完成 ##
