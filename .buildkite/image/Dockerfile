FROM ubuntu:xenial-20200114
RUN apt-get --quiet update \
 && apt-get --quiet install -y build-essential curl \
 && rm -rf /var/lib/apt/lists/*
ARG UID
ENV UID=$UID
ARG USER
ENV USER=$USER
RUN useradd -ms /bin/bash --uid $UID $USER
WORKDIR /home/$USER
USER $USER
