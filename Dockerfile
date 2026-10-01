# 使用官方 Gitea 镜像作为基础
FROM docker.gitea.com/gitea:latest

# 切换到 root 用户，以便执行 chown 操作
USER root

# 创建一个入口点脚本，用于自动修复 /data 目录的权限
RUN cat > /usr/bin/entrypoint-wrapper.sh <<'EOF'
#!/bin/sh
set -e

# 检查 /data 目录是否存在，如果存在则将其所有权赋予 UID 1000 (git 用户)
# 这是 Gitea 默认运行用户，能有效解决挂载卷的权限问题
if [ -d "/data" ]; then
    chown -R 1000:1000 /data
fi

# 执行官方镜像原有的入口点脚本，将命令行参数传递过去
exec /usr/bin/entrypoint "$@"
EOF

# 赋予脚本可执行权限
RUN chmod +x /usr/bin/entrypoint-wrapper.sh

# 将容器的入口点替换为我们的包装脚本
ENTRYPOINT ["/usr/bin/entrypoint-wrapper.sh"]

# 切换回官方镜像默认的非 root 用户 (通常是 git, UID 1000)
# 这一步至关重要，能确保 Gitea 以最小权限运行，提升安全性
USER 10001
