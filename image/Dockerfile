FROM jupyterhub/k8s-singleuser-sample:0.11.1

# Add RUN statements to install packages as the $NB_USER defined in the base images.

# Add a "USER root" statement followed by RUN statements to install system packages using apt-get,
# change file permissions, etc.

# If you do switch to root, always be sure to add a "USER $NB_USER" command at the end of the
# file to ensure the image runs as a unprivileged user by default.

USER root

# Install Java
RUN apt-get -y update && \
    apt-get install --no-install-recommends -y \
    openjdk-8-jre-headless \
    ca-certificates-java \
    git \
    curl \
    vim \
    nano \
    emacs-nox \
    gzip \
    zip \
    unzip \
    bzip2 && \
    rm -rf /var/lib/apt/lists/*

# Copy start up scripts
COPY scripts/start-spark.sh /usr/local/bin/
COPY scripts/entrypoint.sh /usr/local/bin/
COPY scripts/pre-start-source.sh /usr/local/bin/
ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]

# Install AXS
ARG AXS_VERSION=v3.0.0-preview-scala-fix
ENV AXS_URL=https://github.com/stevenstetzler/axs/releases/download/$AXS_VERSION/axs-distribution.tgz
ENV AXS_HOME=/opt/axs

RUN cd /tmp && \
    wget -q -O axs-distribution.tar.gz $AXS_URL && \
    mkdir $AXS_HOME && \
    tar xf axs-distribution.tar.gz --strip 1 -C $AXS_HOME && \
    rm axs-distribution.tar.gz && \
    chown -R $NB_UID:$NB_GID $AXS_HOME && \
    rm -f /home/$NB_USER/.wget-hsts
# Update environment variables
ENV SPARK_HOME $AXS_HOME
ENV PATH $PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin

USER $NB_UID

# Install required jars for Spark
RUN cd $SPARK_HOME/jars && \
    # access to AWS S3
    curl -O https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk/1.7.4/aws-java-sdk-1.7.4.jar && \
    curl -O https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/2.7.3/hadoop-aws-2.7.3.jar && \
    # Connector for MariaDB for Spark metastore
    curl -O https://downloads.mariadb.com/Connectors/java/connector-java-2.6.0/mariadb-java-client-2.6.0.jar && \
    # link the axs jar to this directory
    axs_jar=$(ls -p $SPARK_HOME/python/axs/*jar | xargs echo | sed 's/ /,/g') && \
    ln -s $axs_jar ./$(basename $axs_jar)

# Install pyarrow, numpy, pandas
RUN conda install --quiet --yes \
    'pyarrow' \
    'numpy' \
    'pandas' && \
    conda clean --all -f -y && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# Install extra packages
RUN conda install --quiet --yes \
    # pytables for Pandas, allows reading of hdf5 files
    'pytables' \
    # plotting
    'matplotlib' \
    # pulling demo notebooks
    'nbgitpuller' \
    # interacting with K8s cluster
    'python-kubernetes' && \
    conda clean --all -f -y && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# Install Jupyter Proxy Server
RUN conda install --quiet --yes \
    'jupyter-server-proxy' \
    -c conda-forge && \
    jupyter labextension install  \
    @jupyterlab/server-proxy && \
    conda clean --all -f -y && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# Install nbgitpuller
RUN python -m pip install nbgitpuller

# Install nbresuse
RUN python -m pip install nbresuse