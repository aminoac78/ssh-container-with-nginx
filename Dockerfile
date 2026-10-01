# 使用官方 Gitea 镜像作为基础
FROM docker.gitea.com/gitea:latest

# 切换回官方镜像默认的非 root 用户 (通常是 git, UID 1000)
# 这一步至关重要，能确保 Gitea 以最小权限运行，提升安全性
USER 10001
