#!/bin/sh
set -e

# 检查 /data 目录是否存在，如果存在则将其所有权赋予 UID 1000 (git 用户)
# 这是 Gitea 默认运行用户，能有效解决挂载卷的权限问题
if [ -d "/data" ]; then
    chown -R 1000:1000 /data
fi

# 执行官方镜像原有的入口点脚本，将命令行参数传递过去
exec /usr/bin/entrypoint "$@"
