FROM alpine:latest

# 安装依赖：SSH、Nginx、Cloudflared、bash
RUN apk add --no-cache openssh nginx bash curl && \
    # 设置 root 密码
    echo "root:123456" | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    # 创建必要目录
    mkdir -p /var/run/sshd /run/nginx /etc/cloudflared && \
    # 生成 SSH host keys
    ssh-keygen -A && \
    rm -rf /var/cache/apk/*
    #touch /etc/nginx/nginx.conf
# 创建 UID=10014 的用户
RUN addgroup -g 10014 devgroup && \
    adduser -D -u 10014 -G devgroup devuser

# 给 devuser sudo 权限（可选）
RUN echo "devuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers


# 复制 Nginx 配置
#COPY nginx.conf /etc/nginx/nginx.conf

# 复制 Cloudflared 配置
#COPY config.yml /etc/cloudflared/config.yml

# 启动脚本
#COPY start.sh /start.sh
#RUN chmod +x /start.sh

# 暴露端口（容器内）
EXPOSE  22 80


#CMD ["/start.sh"]
RUN chown -R 10014:10014 /home/devuser
# 切换到该用户（⚠️ 必须用 UID）
# 1. 确保目录存在并属于非 root 用户
RUN mkdir -p /home/devuser/ssh_keys
RUN chown -R devuser:devgroup /home/devuser/ssh_keys

USER 10014

# 2. 在 CMD 启动时实时生成（即便镜像里没打包进去，启动时也会立刻创建）
CMD ["sh", "-c", "\
    # 如果密钥不存在，则生成
    if [ ! -f /home/devuser/ssh_keys/ssh_host_rsa_key ]; then \
        ssh-keygen -q -t rsa -N '' -f /home/devuser/ssh_keys/ssh_host_rsa_key; \
    fi; \
    # 强制 sshd 使用我们指定的密钥文件和非 22 端口
    /usr/sbin/sshd -D \
        -p 2222 \
        -h /home/devuser/ssh_keys/ssh_host_rsa_key \
        -o 'PidFile /home/devuser/ssh_keys/sshd.pid' \
        -o 'StrictModes no' & \
    nginx -g 'daemon off;' \
"]
