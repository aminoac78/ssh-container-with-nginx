FROM docker.gitea.com/gitea:latest-rootless

# rootless 镜像默认以 UID 1000 运行，平台要求 10001-20000
# 通过环境变量指定，无需修改 /etc/passwd
ENV USER_UID=10001
ENV USER_GID=10001
