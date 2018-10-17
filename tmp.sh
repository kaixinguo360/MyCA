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
if [[ $1 = "-h" || $1 = "--help" || $1 = "" ]];then
  echo "用法: $0 [-d Days -o Output]"
  echo -e "\t-d 证书有效期(天)(默认1)"
  echo -e "\t-o 证书输出位置"
  exit 0
fi

while getopts "d:o:" arg #选项后面的冒号表示该选项需要参数
do
    case $arg in
        d)
           Days=$OPTARG
           ;;
        o)
           Output=$(readlink -f $OPTARG)
           ;;
        ?)  #当有不认识的选项的时候arg为?
           echo "未知选项"
           exit 1
           ;;
    esac
done

CA_ROOT=$(dirname $(readlink -f $0))

## 正式安装开始 ##


# 设置过期日期
if [[ "${Days}" == "" ]]; then
    Days=1
fi

# 生成证书
cd ${CA_ROOT}
./issue.sh -n kaixinguo.tmp -d ${Days} -e kaixinguo@kaixinguo.site -f

# 导出证书
./export.sh -n kaixinguo.tmp -p ${Output}
