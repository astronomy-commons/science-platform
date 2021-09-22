FROM jupyterhub/k8s-singleuser-sample:1.1.3

# Add RUN statements to install packages as the $NB_USER defined in the base images.

# Add a "USER root" statement followed by RUN statements to install system packages using apt-get,
# change file permissions, etc.

# If you do switch to root, always be sure to add a "USER $NB_USER" command at the end of the
# file to ensure the image runs as a unprivileged user by default.

USER root

# Install Java
RUN apt-get -y update \
 && apt-get install --no-install-recommends -y \
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
 && rm -rf /var/lib/apt/lists/*

# Copy start up scripts
COPY scripts/start-spark.sh /usr/local/bin/
COPY scripts/entrypoint.sh /usr/local/bin/
COPY scripts/pre-start-source.sh /usr/local/bin/
ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]

# Install AXS
ARG AXS_VERSION=v1.1-beta3
ENV AXS_URL=https://github.com/astronomy-commons/axs/releases/download/$AXS_VERSION/axs-$AXS_VERSION.tgz
ENV AXS_HOME=/opt/axs

RUN cd /tmp \
 && wget -q -O axs-distribution.tar.gz $AXS_URL \
 && mkdir $AXS_HOME \
 && tar xf axs-distribution.tar.gz --strip 1 -C $AXS_HOME \
 && rm axs-distribution.tar.gz \
 && chown -R $NB_UID:$NB_GID $AXS_HOME \
 && rm -f /home/$NB_USER/.wget-hsts
# Update environment variables
ENV SPARK_HOME $AXS_HOME
ENV PATH $PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin

USER $NB_UID

# Install required jars for Spark
RUN cd $SPARK_HOME/jars \
    # access to AWS S3
 && curl -O https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.11.874/aws-java-sdk-bundle-1.11.874.jar \
 && curl -O https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.2.0/hadoop-aws-3.2.0.jar \
    # Connector for MariaDB for Spark metastore
 && curl -O https://downloads.mariadb.com/Connectors/java/connector-java-2.7.3/mariadb-java-client-2.7.3.jar

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
    'python-kubernetes'
    
# Install packages from conda forge
RUN mamba install --quiet --yes -c conda-forge \
    # server proxy extension
    'jupyter-server-proxy' \
    # resource usage extension
    'jupyter-resource-usage'

# Install packages with pip
RUN python -m pip install \
    jupyterlab-topbar \
    jupyterlab-system-monitor \
    nbgitpuller

# Install labextensions
RUN jupyter labextension install \
    jupyterlab-topbar-text

# Clean Conda
RUN conda clean --all -f -y \
 && fix-permissions $CONDA_DIR \
 && fix-permissions /home/$NB_USER
