FROM ubuntu:18.04

USER root
RUN apt-get -y update
RUN apt-get install --no-install-recommends -y \
    openssh-server \
    openssh-client \
    python3 \
    vim \
    jq \
    curl \
    dnsutils
RUN rm -rf /var/lib/apt/lists/*

# Expose SSH port
EXPOSE 22
# Run as root
USER root
COPY common.sh /usr/local/bin/common.sh
COPY start-ssh.sh /usr/local/bin/start-ssh.sh
ENTRYPOINT ["tini", "-g", "--", "start-ssh.sh"]