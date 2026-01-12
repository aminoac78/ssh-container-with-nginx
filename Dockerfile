FROM alpine:latest

# 1. 安装基础包
RUN apk add --no-cache openssh nginx bash curl && \
    rm -rf /var/cache/apk/*

# 2. 创建用户并设置密码 (在 root 权限下操作)
RUN addgroup -g 10014 devgroup && \
    adduser -D -u 10014 -G devgroup devuser && \
    # 设置 root 和 devuser 的密码为 123456 (你可以修改这里)
    echo "root:123456" | chpasswd && \
    echo "devuser:123456" | chpasswd && \
    # 允许 SSH 密码登录
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

RUN rm -rf /var/lib/nginx/logs && \
    ln -s /tmp /var/lib/nginx/logs
    
# 1. 在构建阶段直接生成一个特殊的 Nginx 配置文件，全部指向 /tmp
RUN echo 'worker_processes auto; \
pid /tmp/nginx.pid; \
events { worker_connections 1024; } \
http { \
    include /etc/nginx/mime.types; \
    client_body_temp_path /tmp/nginx/client_body; \
    proxy_temp_path /tmp/nginx/proxy; \
    fastcgi_temp_path /tmp/nginx/fastcgi; \
    uwsgi_temp_path /tmp/nginx/uwsgi; \
    scgi_temp_path /tmp/nginx/scgi; \
    access_log /tmp/access.log; \
    error_log /tmp/error.log; \
    server { \
        listen 8080; \
        location / { \
            return 200 "Nginx is running on Choreo!"; \
        } \
    } \
}' > /home/devuser/nginx_temp.conf

USER 10014
EXPOSE 2222 8080

CMD ["sh", "-c", "\
    # a. 准备 /tmp 目录
    mkdir -p /tmp/ssh_keys /tmp/nginx/client_body /tmp/nginx/proxy /tmp/nginx/fastcgi /tmp/nginx/uwsgi /tmp/nginx/scgi; \
    \
    # b. 生成 SSH 密钥
    if [ ! -f /tmp/ssh_keys/ssh_host_ed25519_key ]; then \
        echo 'y' | ssh-keygen -q -t ed25519 -N '' -f /tmp/ssh_keys/ssh_host_ed25519_key; \
        echo 'y' | ssh-keygen -q -t rsa -N '' -f /tmp/ssh_keys/ssh_host_rsa_key; \
    fi; \
    \
    # c. 启动 SSHD
    /usr/sbin/sshd -D -e \
        -p 2222 \
        -h /tmp/ssh_keys/ssh_host_rsa_key \
        -h /tmp/ssh_keys/ssh_host_ed25519_key \
        -o 'PidFile /tmp/sshd.pid' \
        -o 'StrictModes no' & \
    \
    # d. 启动 Nginx (显式指定我们的配置文件)
    nginx -c /home/devuser/nginx_temp.conf -g 'daemon off;' \
"]
