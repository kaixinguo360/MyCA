#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# 设置静态参数
CA_ROOT=$(dirname $(readlink -f $0))

# 读取输入参数
if [[ $1 = "-h" || $1 = "--help" || $1 = "" ]];then
  echo -e "用法: $0 功能 [参数|选项]"
  exit 0
fi

# 运行指定命令
NAME=$1
shift
${CA_ROOT}/${NAME}.sh $@
