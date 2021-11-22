FROM jupyterhub/k8s-hub:1.1.3

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

RUN groupadd -g 996 admin \
 && useradd --system admin -u 999 -g 996 -m \
 && usermod -a -G jovyan admin
 # get sudoers config from file on NFS
 && echo "#includedir /home/admin/etc/sudoers.d" >> /etc/sudoers

USER admin