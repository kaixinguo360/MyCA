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
  echo "用法: $0 [-o Output]"
  echo -e "\t-o 输出路径"
  exit 0
fi

while getopts "o:" arg #选项后面的冒号表示该选项需要参数
do
    case $arg in
        o)
           Output=$(readlink -f $OPTARG)
           ;;
        ?)  #当有不认识的选项的时候arg为?
           echo "未知选项"
           exit 1
           ;;
    esac
done

CA_ROOT=$(realpath $(dirname $0)/..)
CA_DATA=$CA_ROOT/data


## 正式备份开始 ##


# 生成证书保存目录
Output="${Output}/myca.bak"
mkdir -p ${Output} > /dev/null

# 备份文件
cp -a ${CA_DATA} ${Output}/data
cp /usr/lib/ssl/openssl.cnf ${Output}/openssl.cnf


