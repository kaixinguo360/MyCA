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
[[ -d "${CA_DATA}/private" && ! -r "${CA_DATA}/private" ]] && { echo "Error: Permission denied. Please make sure you have the correct access rights"; exit 1; }

# 读取输入参数
if [[ $1 = "-h" || $1 = "--help" || $1 = "" ]];then
  echo "用法: $0 [-o path] [-i file] [-f]"
  echo -e "\t-o path 将数据归档到指定路径"
  echo -e "\t-i file 从指定归档文件中恢复"
  echo -e "\t-f      强制覆盖现有数据"
  exit 0
fi

while getopts "o:i:f" arg #选项后面的冒号表示该选项需要参数
do
    case $arg in
        o)
           Output=$(readlink -f $OPTARG)
           ;;
        i)
           Input=$(readlink -f $OPTARG)
           ;;
        f)
           Force=true
           ;;
        ?)  #当有不认识的选项的时候arg为?
           echo "未知选项"
           exit 1
           ;;
    esac
done


## 正式备份开始 ##

cd ${CA_ROOT}

# 备份数据
if [ -n "${Output}" ];then
    mkdir -p ${Output}
    FilePath=${Output}/myca_$(date "+%Y%m%d_%H%M%S").tar.gz
    tar -zcf $FilePath ./data
    echo "备份成功!"
    echo "归档文件路径: $FilePath"
fi

# 还原数据
if [ -n "${Input}" ];then
    if [[ -e ./data && ! $Force ]];then
        echo "检测到已有数据, 停止覆盖!"
        exit 1
    fi
    if [ ! -f "${Input}" ];then
        echo "无效的输入文件! (${Input})"
        exit 1
    fi
    rm -rf ./data
    echo "正在解压归档文件..."
    tar -zxvf ${Input} ./data
    echo "还原成功!"
fi


