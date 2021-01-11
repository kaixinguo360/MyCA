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

# 设置默认参数
CommonName="tmp"

# 检查是否已初始化
[[ ! -d "${CA_DATA}/private" ]] && { echo "找不到CA根证书! 是否未初始化?"; exit 1; }

# 检查是否有操作权限
[[ -d "${CA_DATA}/private" && ! -r "${CA_DATA}/private" ]] && { echo "Error: Permission denied. Please make sure you have the correct access rights"; exit 1; }

# 读取输入参数
if [[ $1 = "-h" || $1 = "--help" || $1 = "" ]];then
  echo "用法: $0 [-d Days -o Output]"
  echo "生成PKCS12格式的临时证书"
  echo -e "\t-d 证书有效期(天) (默认: 1)"
  echo -e "\t-n 主机名称 (默认: tmp)"
  echo -e "\t-p 证书保护密码"
  echo -e "\t-o 证书输出位置"
  echo -e "\t-a 生成证书时的附加参数, 具体参阅issue命令"
  exit 0
fi

while getopts "d:n:p:o:a:" arg #选项后面的冒号表示该选项需要参数
do
    case $arg in
        d)
           Days=$OPTARG
           ;;
        n)
           CommonName=$OPTARG
           ;;
        p)
           Passwd=$OPTARG
           ;;
        o)
           Output=$(readlink -f $OPTARG)
           ;;
        a)
           AdditionArgs="$OPTARG"
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
${CA_ROOT}/bin/issue.sh \
    -n $CommonName \
    -d ${Days} \
    -f \
    $AdditionArgs

# 导出证书
${CA_ROOT}/bin/export.sh \
    -n $CommonName \
    -p ${Output} \
    `[ -n "${Passwd}" ] && echo "-o ${Passwd}"`

