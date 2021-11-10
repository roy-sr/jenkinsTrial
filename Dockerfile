FROM ubuntu:20.04

ARG ROOT_CONTAINER=ubuntu:focal-20200423@sha256:238e696992ba9913d24cfc3727034985abd136e08ee3067982401acdc30cbf3f
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
USER root
# Install all OS dependencies for notebook server that starts but lacks all
# features (e.g., download as all possible file formats)
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -y
RUN apt-get install -yq --no-install-recommends  -y
RUN apt-get install libglib2.0-0  -y
RUN apt-get install libsm6  -y
RUN apt-get install libxrender1  -y
RUN apt-get install libxext6 -y
RUN apt-get install libgl1-mesa-glx  -y
RUN apt-get install python3-distutils  -y
RUN apt-get install wget  -y
RUN apt-get install bzip2  -y
RUN apt-get install ca-certificates  -y
RUN apt-get install sudo  -y
RUN apt-get install locales  -y
RUN apt-get install fonts-liberation  -y
RUN apt-get install run-one  -y
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen
RUN apt-get update -y
RUN apt-get install libgtk2.0-dev -y
# Configure environment
ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
ENV PATH=$CONDA_DIR/bin:$PATH \
    HOME=/usr/src

WORKDIR $HOME
ARG PYTHON_VERSION='3.8' 
# Setup work directory for backward-compatibility
RUN    mkdir -p $CONDA_DIR
# Install conda as jovyan and check the md5 sum provided on the download site
ENV MINICONDA_VERSION=4.9.2 \
    MINICONDA_MD5=3143b1116f2d466d9325c206b7de88f7 \
    CONDA_VERSION=4.9.2
WORKDIR /tmp  
RUN wget --quiet https://repo.continuum.io/miniconda/Miniconda3-py37_${MINICONDA_VERSION}-Linux-x86_64.sh && \
    echo "${MINICONDA_MD5} *Miniconda3-py37_${MINICONDA_VERSION}-Linux-x86_64.sh" | md5sum -c - && \
    /bin/bash Miniconda3-py37_${MINICONDA_VERSION}-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Miniconda3-py37_${MINICONDA_VERSION}-Linux-x86_64.sh && \
    echo "conda ${CONDA_VERSION}" >> $CONDA_DIR/conda-meta/pinned && \
    conda config --system --prepend channels conda-forge && \
    conda config --system --set auto_update_conda false && \
    conda config --system --set show_channel_urls true && \
    conda config --system --set channel_priority strict && \
    if [ ! $PYTHON_VERSION = 'default' ]; then conda install --yes python=$PYTHON_VERSION; fi && \
    conda list python | grep '^python ' | tr -s ' ' | cut -d '.' -f 1,2 | sed 's/$/.*/' >> $CONDA_DIR/conda-meta/pinned && \
    conda install --quiet --yes conda && \
    conda install --quiet --yes pip && \
    conda update --all --quiet --yes && \
    conda clean --all -f -y 
############################################################################
##########################  #############################
############################################################################
WORKDIR $HOME
ENV HOME=/usr/src
RUN mkdir /home/prod_code 
COPY . /home/prod_code
############################################################################
########################## Dependency #############################
############################################################################
WORKDIR /home/prod_code
RUN pip install --upgrade pip 
RUN pip install -r requirements.txt
# Clean installation
RUN conda clean --all -f -y 