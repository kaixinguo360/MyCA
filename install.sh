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

# 读取输入参数
if [[ $1 = "-h" || $1 = "--help" ]];then
  echo "用法: $0 密码 主机名 邮箱"
  exit 0
fi

PASSWORD=$1
COMMON_NAME=$2
EMAIL=$3

if [[ $PASSWORD = "" ]];then
while true :
do
    read -s -p '请设置CA根密码: ' PASSWORD_1
    echo ''
    read -s -p '再输一遍: ' PASSWORD_2
    echo ''
    if [ "${PASSWORD_1}" = "${PASSWORD_2}" ]; then
        PASSWORD=${PASSWORD_1}
        break
    else
        echo -e "两次输入密码不一致!\n"
    fi
done

read -p "请输入你的主机名: " COMMON_NAME
read -p "请输入你的邮箱地址: " EMAIL

fi

CA_ROOT=$(dirname $(readlink -f $0))


## 正式安装开始 ##

cd ${CA_ROOT}

# 设置权限
chmod +x ca.sh myca.sh

# 安装CA
./ca.sh $PASSWORD $COMMON_NAME $EMAIL

# 创建Alias
cat > myca.sh.env << HERE
export MYCA_WORKING_DIR="${CA_ROOT}"
alias myca.sh="${CA_ROOT}/myca.sh"
HERE

# 加入.bashrc
HAS_ADDED=$(sed -n "#${CA_ROOT}/myca.sh.env#p" ~/.bashrc)
if [ ! "${HAS_ADDED}" = "" ]; then
cat >> ~/.bashrc << HERE
. "${CA_ROOT}/myca.sh.env"
HERE
fi

# 完成安装，删除临时文件
#rm -rf install.sh ca.sh

