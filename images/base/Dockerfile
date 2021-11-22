FROM jupyterhub/k8s-singleuser-sample:1.1.3

USER root

# Update cache
RUN apt-get -y update \
 && apt-get -y install apt-file \
 && apt-file update

# Install common packages
RUN apt-get install --no-install-recommends --fix-missing -y \
    openjdk-11-jre-headless \
    ca-certificates-java \
    git \
    curl \
    vim \
    nano \
    emacs-nox \
    gzip \
    zip \
    unzip \
    bzip2
    openssh-server \
    openssh-client \
    jq \
    dnsutils \
    htop
RUN rm -rf /var/lib/apt/lists/*

RUN groupadd -g 996 admin \
 && useradd admin -u 999 -g 996 -m \
 && usermod -a -G users admin \
 # get sudoers config from file on NFS
 && echo "#includedir /home/admin/etc/sudoers.d" >> /etc/sudoers

COPY scripts/start-spark.sh /usr/local/bin
COPY scripts/start-ssh.sh /usr/local/bin
COPY scripts/entrypoint.sh /usr/local/bin
ENTRYPOINT ["tini", "-g", "--", "/usr/local/bin/entrypoint.sh"]

USER ${NB_USER}