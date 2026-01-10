FROM astronomycommons/public-hub-singleuser:0.6.3

USER root

# Update cache
RUN apt-get -y update \
 && apt-get -y install apt-file \
 && apt-file update

# Install LSST dependencies https://pipelines.lsst.io/v/DM-14099/install/prereqs/debian.html
RUN apt-get install --no-install-recommends -y \
    bison \
    ca-certificates \
    cmake \
    curl \
    # Java 11 already installed
    # default-jre \ 
    flex \
    gettext \
    git \
    libbz2-dev \
    libcurl4-openssl-dev \
    libfontconfig1 \
    libglib2.0-dev \
    libncurses5-dev \
    libreadline6-dev \
    libx11-dev \
    libxrender1 \
    libxt-dev \
    m4 \
    make \
    perl-modules \
    zlib1g-dev

# Install extra packages
RUN apt-get install --no-install-recommends -y \
    joe \
    telnet \
    bind9utils \ 
    traceroute \
    vim \
    emacs \
    nano \
    cron \
    git \
    sextractor \
    psfex \
    swarp \
    scamp \
    mariadb-client mariadb-server mycli \
    postgresql 

# Install Desktop
RUN apt-get -y install \
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

# Install ds9
RUN cd /usr/local/bin \
 && curl -L http://ds9.si.edu/download/ubuntu18/ds9.ubuntu18.8.4.1.tar.gz | tar xzvf -

#
# Install github API packages to system python (which will be safe to use by
# root)
#
RUN apt-get -y install python3-pip
RUN /usr/bin/pip3 install PyGithub

# remove apt cache files
RUN apt-get -y clean \
 && rm -rf /var/lib/apt/lists/*

#
# Work to be done by 'admin' (package installs, path adjustments)
#

USER admin

# Grab conda envs from the NFS server
RUN rmdir /opt/conda/envs && \
    ln -s /home/opt/conda/envs /opt/conda/envs

# Link to the LSST stack
RUN ln -s /home/opt/lsst /opt/lsst

# Pick up the LSST environment's kernel as the default
RUN rm -r /opt/conda/share/jupyter/kernels && \
    ln -s /opt/conda/envs/lsst/share/jupyter/kernels /opt/conda/share/jupyter/kernels

# Add nb_conda_kernels
RUN mamba install nb_conda_kernels

# Clean in-container conda install ...
# ... and work around a conda bug when pkgs dir is empty (see
# https://github.com/conda/conda/issues/7267#issuecomment-458661530)
RUN conda clean --all -f -y \
 && mkdir /opt/conda/pkgs && touch /opt/conda/pkgs/urls.txt


#
# More root work
#

USER root
# Hide system kernels from nb_conda_kernels
# Place user-defined conda environments into the user's directory
RUN printf '\
\n\
c.CondaKernelSpecManager.env_filter = r"^/opt/.*$" \n\
c.CondaKernelSpecManager.name_format = "'"{0}"' ({1})" \n'\
>> /etc/jupyter/jupyter_notebook_config.py

# Get rid of the jovyan user's (huge) home directory
RUN rm -rf /home/jovyan
# STEVEN add
RUN userdel jovyan

#
# Startup scripts
#
COPY scripts/get-org-memberships.py /usr/local/bin/
COPY scripts/startup.sh /usr/local/bin/
COPY scripts/run-startup.sh /usr/local/bin/start-notebook.d/

USER root
