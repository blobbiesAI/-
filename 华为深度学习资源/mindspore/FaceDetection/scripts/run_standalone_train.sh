#!/bin/bash
# Copyright 2020-2021 Huawei Technologies Co., Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ============================================================================

#检查脚本的输入参数的数量是否正确
if [ $# != 3 ] && [ $# != 4 ]
then
    echo "Usage: bash run_standalone_train.sh [PLATFORM] [MINDRECORD_FILE] [USE_DEVICE_ID] [PRETRAINED_BACKBONE]"
    echo "   or: bash run_standalone_train.sh [PLATFORM] [MINDRECORD_FILE] [USE_DEVICE_ID]"
    exit 1    #exit 0 means success,others mean failure
fi

#realpath 用于获取指定目录或文件的绝对路径
get_real_path(){
  if [ "${1:0:1}" == "/" ]; then  #检查文件是否在根目录，如果是，直接输出，即是绝对路径。
    echo "$1"
  else
    echo "$(realpath -m $PWD/$1)" #如果文件不在根目录，利用realpath函数计算绝对路径。
  fi
}

#当前工作目录
current_exec_path=$(pwd)
echo ${current_exec_path}

#会返回文件的上一层路径：如果是目录 /usr/bin/，则同理返回上一层路径 /usr。
dirname_path=$(dirname "$(pwd)")
echo ${dirname_path}

export PYTHONPATH=${dirname_path}:$PYTHONPATH

export RANK_SIZE=1

SCRIPT_NAME='train.py'

ulimit -c unlimited  #对生成的core文件大小无限制

PLATFORM=$1
MINDRECORD_FILE=$(get_real_path $2)
USE_DEVICE_ID=$3
PRETRAINED_BACKBONE=''

#如果预训练，计算预训练权值文件目录
if [ $# == 4 ]
then
    PRETRAINED_BACKBONE=$(get_real_path $4)
    if [ ! -f $PRETRAINED_BACKBONE ]
    then
        echo "error: PRETRAINED_PATH=$PRETRAINED_BACKBONE is not a file"
    exit 1
    fi
fi

echo $PLATFORM
echo $MINDRECORD_FILE
echo $USE_DEVICE_ID
echo $PRETRAINED_BACKBONE

echo 'start training'
export RANK_ID=0
rm -rf ${current_exec_path}/device$USE_DEVICE_ID #删除当前目录下的所有文件,这个命令很危险，应避免使用。所删除的文件，一般都不能恢复！
echo 'start device '$USE_DEVICE_ID
mkdir ${current_exec_path}/device$USE_DEVICE_ID  #新建目录
cd ${current_exec_path}/device$USE_DEVICE_ID  || exit
dev=`expr $USE_DEVICE_ID + 0`
export DEVICE_ID=$dev
python ${dirname_path}/${SCRIPT_NAME} \
    --run_platform=$PLATFORM \
    --mindrecord_path=$MINDRECORD_FILE \
    --pretrained=$PRETRAINED_BACKBONE > train.log  2>&1 &

echo 'running'
