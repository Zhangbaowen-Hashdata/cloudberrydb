#!/bin/bash

# 获取最新的 tag
echo "工作空间是 $GITHUB_WORKSPACE"


pwd
ls -al
git fetch --tags
target_dir="/tmp/release"
timestamp=$(date +"%Y%m%d")

# 检查目标目录是否存在
if [ -d "$target_dir" ]; then
    # 如果目录存在，则删除目录
    rm -rf "$target_dir"
    echo "已删除目录 $target_dir"
else
    echo "目录 $target_dir 不存在"
    mkdir /tmp/release
fi


pwd
ls -al

latest_tag=$(git tag | sort -V -r | head -n 1)

echo "已存在tag最新一条为 $latest_tag"
# 从最新的 tag 中提取版本号部分作为变量 version

main_version=$(echo $latest_tag | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+')
echo "最新的cbdb主版本是$main_version"

new_tag="$main_version.$timestamp-nightly"

echo "新的 nightly 版本号为: $new_tag"

cd $GITHUB_WORKSPACE