#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

## 初始化安装参数 ##

# 设置静态参数
CA_ROOT=$(realpath $(dirname $0)/..)
CA_DATA=$CA_ROOT/data

# 检查是否已初始化
[[ ! -d "${CA_DATA}/private" ]] && { echo "找不到CA根证书! 是否未初始化?"; exit 1; }

# 检查是否有操作权限
[[ -d "${CA_DATA}/private" && ! -r "${CA_DATA}/private" ]] && { echo "Error: Permission denied. Please make sure you have the correct access rights"; exit 1; }

# 读取输入参数
if [[ $1 = "-h" || $1 = "--help" ]];then
  echo -e "用法: $0 [CommonName]"
  exit 0
fi

# 读取输入参数
CommonName=$1

cd ${CA_DATA}

## 开始 ##

# 查看指定证书
if [ -n "${CommonName}" ];then
    FileName=$(echo "$CommonName"|sed 's/\*/_/g')
    CERT_HOME="mycerts/${FileName}"
    CRT_LOCATION="${CERT_HOME}/${FileName}.crt"
    KEY_LOCATION="${CERT_HOME}/${FileName}.key"

    if [ -e ${CRT_LOCATION} ];then
        CRT=$(< ${CRT_LOCATION})
        if [ -z "$CRT" ];then
            echo "${CommonName}证书不合法！"
            exit 1
        fi
    else
        echo "无法找到${CommonName}证书！它可能不存在或您没有读取权限"
        exit 1
    fi

    cat "$CRT_LOCATION"
else
    ls -1 mycerts/
fi

