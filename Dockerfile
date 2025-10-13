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
EXPOSE  80

CMD sh -c "/usr/sbin/sshd && nginx -g 'daemon off;'"
#CMD ["/start.sh"]
# 切换到该用户（⚠️ 必须用 UID）
USER 10014

WORKDIR /home/devuser
