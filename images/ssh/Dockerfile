FROM ubuntu:22.04

USER root
RUN apt-get -y update
RUN apt-get install --no-install-recommends -y \
    openssh-server \
    openssh-client \
    python3 \
    vim \
    jq \
    curl \
    dnsutils \
    iputils-ping \
    traceroute \
    netcat \
    sudo
RUN rm -rf /var/lib/apt/lists/* \
 && rm -rf /etc/ssh/*key*

ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

RUN useradd --no-create-home jovyan -s /bin/bash -u 1000 -g 100

# Expose SSH port
EXPOSE 22
COPY start-ssh.sh /usr/local/bin/start-ssh.sh
ENTRYPOINT ["/tini", "-g", "--"]
CMD ["start-ssh.sh"]