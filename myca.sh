#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# 设置静态参数
CA_ROOT=$(dirname $(readlink -f $0))

# 读取输入参数
if [[ $1 = "-h" || $1 = "--help" || $1 = "" ]];then
  echo -e "用法: $0 功能 [参数|选项]"
  echo -e "    功能: issue     生成新的证书"
  echo -e "          export    导出证书"
  echo -e "          backup    备份数据"
  echo -e "          tmp       临时证书"
  echo -e "          list      查看证书"
  echo -e "          delete    删除证书"
  exit 0
fi

# 运行指定命令
NAME=$1
shift
${CA_ROOT}/bin/${NAME}.sh $@
