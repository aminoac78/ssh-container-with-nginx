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

# 3. 预配置 Nginx (使其不再访问只读的 /var/lib/nginx)
RUN sed -i 's/listen 80;/listen 8080;/g' /etc/nginx/http.d/default.conf && \
    sed -i 's|/run/nginx.pid|/tmp/nginx.pid|g' /etc/nginx/nginx.conf && \
    sed -i 's/user nginx;//g' /etc/nginx/nginx.conf

# 切换到非 root 用户
USER 10014
EXPOSE 2222 8080

# 4. 运行时 CMD (全部在 /tmp 下操作)
CMD ["sh", "-c", "\
    # a. 在可写的 /tmp 下创建必要子目录
    mkdir -p /tmp/ssh_keys /tmp/nginx/client_body /tmp/nginx/proxy /tmp/nginx/fastcgi /tmp/nginx/uwsgi /tmp/nginx/scgi; \
    \
    # b. 动态生成 SSH 密钥 (如果镜像层没保留，这里会实时生成)
    ssh-keygen -q -t ed25519 -N '' -f /tmp/ssh_keys/ssh_host_ed25519_key <<< 'y'; \
    ssh-keygen -q -t rsa -N '' -f /tmp/ssh_keys/ssh_host_rsa_key <<< 'y'; \
    \
    # c. 启动 SSHD (指向 /tmp，绕过只读限制)
    /usr/sbin/sshd -D -e \
        -p 2222 \
        -h /tmp/ssh_keys/ssh_host_rsa_key \
        -h /tmp/ssh_keys/ssh_host_ed25519_key \
        -o 'PidFile /tmp/sshd.pid' \
        -o 'StrictModes no' & \
    \
    # d. 启动 Nginx (覆盖所有只读路径)
    nginx -g 'daemon off; \
             error_log /tmp/nginx_error.log; \
             client_body_temp_path /tmp/nginx/client_body; \
             proxy_temp_path /tmp/nginx/proxy; \
             fastcgi_temp_path /tmp/nginx/fastcgi; \
             uwsgi_temp_path /tmp/nginx/uwsgi; \
             scgi_temp_path /tmp/nginx/scgi;' \
"]
