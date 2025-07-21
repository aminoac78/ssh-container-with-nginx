FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && \
    apt install -y openssh-server sudo net-tools && \
    mkdir /var/run/sshd && \
    echo 'root:toor' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    echo 'export VISIBLE=now' >> /etc/profile

RUN mkdir -p /root/.ssh

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
