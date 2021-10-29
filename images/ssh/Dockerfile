FROM jupyterhub/k8s-singleuser-sample:1.1.3

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

COPY entrypoint.sh /usr/local/sbin
ENTRYPOINT ["tini", "-g", "/usr/local/sbin/entrypoint.sh"]