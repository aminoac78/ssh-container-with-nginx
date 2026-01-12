FROM alpine:latest

# 1. 安装依赖
RUN apk add --no-cache openssh nginx bash curl && \
    rm -rf /var/cache/apk/*

# 2. 创建用户并准备目录（在 root 阶段完成）
RUN addgroup -g 10014 devgroup && \
    adduser -D -u 10014 -G devgroup devuser && \
    mkdir -p /home/devuser/ssh_keys /home/devuser/run/nginx /home/devuser/logs && \
    # 修正权限，确保 devuser 有权读写这些地方
    chown -R 10014:10014 /home/devuser /var/lib/nginx /var/log/nginx

# 3. 预先配置 Nginx 监听非 80 端口（否则 devuser 启动会报错）
RUN sed -i 's/listen 80;/listen 8080;/g' /etc/nginx/http.d/default.conf && \
    # 允许 Nginx PID 文件写在用户目录
    sed -i 's|pid /run/nginx.pid;|pid /home/devuser/run/nginx/nginx.pid;|g' /etc/nginx/nginx.conf || true

# 切换到非 root 用户
USER 10014

# 暴露高位端口
EXPOSE 2222 8080

# 4. 运行时的 CMD 逻辑
CMD ["sh", "-c", "\
    # 动态生成 SSH 主机密钥（存放在用户有权写入的地方）
    if [ ! -f /home/devuser/ssh_keys/ssh_host_ed25519_key ]; then \
        ssh-keygen -q -t ed25519 -N '' -f /home/devuser/ssh_keys/ssh_host_ed25519_key; \
        ssh-keygen -q -t rsa -N '' -f /home/devuser/ssh_keys/ssh_host_rsa_key; \
    fi; \
    \
    # 启动 SSHD：指定非 22 端口，指定非标准路径密钥，指定非标准 PID 文件
    /usr/sbin/sshd -D \
        -p 2222 \
        -h /home/devuser/ssh_keys/ssh_host_rsa_key \
        -h /home/devuser/ssh_keys/ssh_host_ed25519_key \
        -o 'PidFile /home/devuser/ssh_keys/sshd.pid' \
        -o 'StrictModes no' & \
    \
    # 启动 Nginx
    nginx -g 'daemon off;' \
"]
