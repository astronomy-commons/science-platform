FROM jupyterhub/k8s-singleuser-sample:1.1.3

# Add RUN statements to install packages as the $NB_USER defined in the base images.

# Add a "USER root" statement followed by RUN statements to install system packages using apt-get,
# change file permissions, etc.

# If you do switch to root, always be sure to add a "USER $NB_USER" command at the end of the
# file to ensure the image runs as a unprivileged user by default.

USER root

# Update cache
RUN apt -y update \
 && apt-get -y update \
 && apt-get -y install apt-file \
 && apt-file update

# Install necessary (Java) and helpful packages
RUN apt-get install --no-install-recommends -y \
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
    bzip2 \
    less

# Install ssh and htop
RUN apt-get install -y --fix-missing \
    openssh-client \ 
    openssh-server \
    htop

# Install Desktop
RUN apt-get install -y --fix-missing \
    dbus-x11 \
    xfce4 \
    xfce4-panel \
    xfce4-session \
    xfce4-settings \
    xorg \
    xubuntu-icon-theme \
    firefox \
 # Disable creation of Music, Documents, etc.. directories
 # ref: https://unix.stackexchange.com/questions/268720/who-is-creating-documents-video-pictures-etc-in-home-directory
 && apt-get remove -y xdg-user-dirs \
 # Disable the Applications|Log Out menu item in XFCE
 # ref: https://github.com/yuvipanda/jupyter-desktop-server/issues/16
 && rm -f /usr/share/applications/xfce4-session-logout.desktop

# remove apt cache files
RUN apt-get -y clean \
 && rm -rf /var/lib/apt/lists/*

# remove SSH keys
RUN rm -rf /etc/ssh/*key*

# Add admin user and group
RUN groupadd -g 996 admin \
 && useradd admin -u 999 -g 996 -m \
 && chsh admin -s /bin/bash \
 # get sudoers config from file on NFS
 && echo "#includedir /home/admin/etc/sudoers.d" >> /etc/sudoers


# Update conda permissions
RUN chown -R admin:admin /opt

# switch to admin for further installs
USER admin
WORKDIR /home/admin
ENV HOME /home/admin

# Install AXS
ENV AXS_VERSION v1.1-beta3
# Update environment variables
ENV SPARK_HOME /opt/axs
ENV PATH $PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin
RUN cd /tmp \
 # Download AXS
 && wget -q -O axs-distribution.tar.gz https://github.com/astronomy-commons/axs/releases/download/${AXS_VERSION}/axs-${AXS_VERSION}.tgz \
 && mkdir $SPARK_HOME \
 && tar xf axs-distribution.tar.gz --strip 1 -C $SPARK_HOME \
 && rm axs-distribution.tar.gz \
 # Install required jars for Spark
 && cd $SPARK_HOME/jars \
 # access to AWS S3
 && curl -O -s https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.11.874/aws-java-sdk-bundle-1.11.874.jar \
 && curl -O -s https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.2.0/hadoop-aws-3.2.0.jar \
 # access to Azure storage
 && curl -O -s https://repo1.maven.org/maven2/org/wildfly/openssl/wildfly-openssl/1.0.7.Final/wildfly-openssl-1.0.7.Final.jar \
 && curl -O -s https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-azure/3.2.2/hadoop-azure-3.2.2.jar \
 # Connector for MariaDB for Spark metastore
 && curl -O -s https://downloads.mariadb.com/Connectors/java/connector-java-2.7.3/mariadb-java-client-2.7.3.jar \
 # Postgres connector
 && curl -O -s https://jdbc.postgresql.org/download/postgresql-42.5.1.jar

# Install mamba
RUN conda install --quiet --yes -c conda-forge mamba

# Install packages from main conda repository
RUN mamba install --quiet --yes \
    # Install AXS dependencies: pyarrow, numpy, pandas, healpy
    'pyarrow' \
    'numpy' \
    'pandas' \
    'healpy' \    
    # pytables for Pandas, allows reading of hdf5 files
    'pytables' \
    # plotting
    'matplotlib' \
    # pulling demo notebooks
    'nbgitpuller' \
    # interacting with K8s cluster
    'python-kubernetes' \
    # Dask
    'dask'
    
# Install packages from conda forge
RUN mamba install --quiet --yes -c conda-forge \
    # server proxy extension
    'jupyter-server-proxy' \
    # resource usage extension
    'jupyter-resource-usage'

# Install jupyter-desktop-server
RUN mamba install -c manics websockify \
 && pip install git+https://github.com/mjuric/jupyter-desktop-server

# Install packages with pip
RUN python -m pip install \
    jupyterlab-topbar \
    jupyterlab-system-monitor \
    nbgitpuller \
    dask_kubernetes \
    adlfs

# Install labextensions
RUN jupyter labextension install \
    jupyterlab-topbar-text

# Clean Conda
RUN conda clean --all -f -y

USER root
# Clean up
RUN rm -rf /home/admin/* /home/jovyan/*

# Copy start up scripts
COPY scripts/entrypoint.sh /usr/local/bin/
COPY scripts/pre-start-source.sh /usr/local/bin/
COPY scripts/start-spark.sh /usr/local/bin/
COPY scripts/start-ssh.sh /usr/local/bin/
ENTRYPOINT [ "tini", "-g", "--", "/usr/local/bin/entrypoint.sh" ]

# Switch to user
USER $NB_USER
WORKDIR /home/$NB_USER
ENV HOME /home/$NB_USER
