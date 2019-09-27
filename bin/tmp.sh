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
CA_DATA=$CA_ROOT/data

# 检查是否有操作权限
[ ! -r "${CA_DATA}/private" ] && { echo "Error: Permission denied. Please make sure you have the correct access rights"; exit 1; }

# 读取输入参数
if [[ $1 = "-h" || $1 = "--help" || $1 = "" ]];then
  echo "用法: $0 [-d Days -o Output]"
  echo -e "\t-d 证书有效期(天)(默认1)"
  echo -e "\t-p 证书保护密码"
  echo -e "\t-o 证书输出位置"
  exit 0
fi

while getopts "d:p:o:" arg #选项后面的冒号表示该选项需要参数
do
    case $arg in
        d)
           Days=$OPTARG
           ;;
        p)
           Passwd=$OPTARG
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


## 正式安装开始 ##

# 设置过期日期
if [[ "${Days}" == "" ]]; then
    Days=1
fi

# 生成证书
cd ${CA_DATA}
${CA_ROOT}/bin/issue.sh -n kaixinguo.tmp -d ${Days} -e kaixinguo@kaixinguo.site -f

# 导出证书
if [[ "$Passwd" == "" ]]; then
    ${CA_ROOT}/bin/export.sh -n kaixinguo.tmp -p ${Output}
else
    ${CA_ROOT}/bin/export.sh -n kaixinguo.tmp -p ${Output} -o ${Passwd}
fi

