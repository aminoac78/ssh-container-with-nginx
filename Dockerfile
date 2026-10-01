# 使用官方 Gitea 镜像作为基础
FROM docker.gitea.com/gitea:latest

# 切换到 root 用户，以便执行 chown 操作
USER root

# 创建一个入口点脚本，用于自动修复 /data 目录的权限
COPY entrypoint-wrapper.sh /usr/bin/entrypoint-wrapper.sh
# 赋予脚本可执行权限
RUN chmod +x /usr/bin/entrypoint-wrapper.sh

# 将容器的入口点替换为我们的包装脚本
ENTRYPOINT ["/usr/bin/entrypoint-wrapper.sh"]

# 切换回官方镜像默认的非 root 用户 (通常是 git, UID 1000)
# 这一步至关重要，能确保 Gitea 以最小权限运行，提升安全性
USER 10001
