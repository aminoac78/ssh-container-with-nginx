FROM alpine:latest

# 安装依赖：SSH、Nginx、Cloudflared、bash
RUN apk add --no-cache openssh nginx bash cloudflared curl && \
    # 设置 root 密码
    echo "root:123456" | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    # 创建必要目录
    mkdir -p /var/run/sshd /run/nginx /etc/cloudflared && \
    # 生成 SSH host keys
    ssh-keygen -A && \
    rm -rf /var/cache/apk/*

# 复制 Nginx 配置
COPY nginx.conf /etc/nginx/nginx.conf

# 复制 Cloudflared 配置
COPY config.yml /etc/cloudflared/config.yml

# 启动脚本
COPY start.sh /start.sh
RUN chmod +x /start.sh

# 暴露端口（容器内）
EXPOSE 22 80

CMD ["/start.sh"]
