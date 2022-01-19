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
RUN rm -rf /var/lib/apt/lists/* \
 && rm -rf /etc/ssh/*key*

ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

# Expose SSH port
EXPOSE 22
# Run as root
USER root
COPY start-ssh.sh /usr/local/bin/start-ssh.sh
ENTRYPOINT ["/tini", "-g", "--"]
CMD ["start-ssh.sh"]