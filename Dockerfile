# Build dh-virtualenv's Debian package within a container for any platform
#
#   docker build --tag dh-venv-builder --build-arg distro=debian:9 .
#   docker build --tag dh-venv-builder --build-arg distro=ubuntu:bionic .
#
#   mkdir -p dist && docker run --rm dh-venv-builder tar -C /dpkg -c . | tar -C dist -xv

ARG distro="debian:stable"
FROM ${distro} AS dpkg-build
RUN apt-get update -qq -o Acquire::Languages=none \
    && env DEBIAN_FRONTEND=noninteractive apt-get install \
        -yqq --no-install-recommends -o Dpkg::Options::=--force-unsafe-io \
        build-essential debhelper devscripts equivs lsb-release libparse-debianchangelog-perl \
        python2 python2-dev dh-exec dh-python curl sphinx-doc sphinx-common python-docutils \
    && apt-get clean && rm -rf "/var/lib/apt/lists"/* \
    && curl https://bootstrap.pypa.io/get-pip.py --output get-pip.py \
    && python2 get-pip.py \
    && pip install setuptools pip sphinx mock sphinx-rtd-theme \
    && ln -s /usr/bin/python2 /usr/bin/python
WORKDIR /dpkg-build
COPY ./ ./
RUN sed -i -re "1s/..unstable/~$(lsb_release -cs)) $(lsb_release -cs)/" debian/changelog \
    && dpkg-buildpackage -us -uc -b && mkdir -p /dpkg && cp -pl /dh-virtualenv[-_]* /dpkg \
    && dpkg-deb -I /dpkg/dh-virtualenv_*.deb
