# debian13's wine 10 is ok for pyinstaller, no need to attach winehq repo
FROM debian:trixie-slim

LABEL org.opencontainers.image.source=https://github.com/jkmnt/docker-pyinstaller-wine
LABEL org.opencontainers.image.description="pyinstaller under wine"
LABEL org.opencontainers.image.licenses=MIT

ARG NODE_VERSION=24.15.0
ARG PYINSTALLER_VERSION=6.6.0
ARG PYTHON_VERSION=3.12.9

ENV DEBIAN_FRONTEND=noninteractive
ENV WINEDEBUG=-all
ENV WINEPREFIX=/opt/wineprefix
ENV WINEPATH="c:\\Python\\;C:\\Python\\Scripts\\"
ENV XDG_RUNTIME_DIR=/tmp/xdg_runtime_dir

# # https://github.com/nodejs/docker-node/blob/58635ae7aaeab55a5c036b59e8ca93d864119cbe/24/bookworm-slim/Dockerfile
# RUN groupadd --gid 1000 node \
#   && useradd --uid 1000 --gid node --shell /bin/bash --create-home node

WORKDIR /tmp

# TODO: add more checksums for different nodes and pythons
COPY SHA256SUMS.txt /tmp

RUN <<EOF
	apt-get update
	apt-get install -y --no-install-recommends git ca-certificates curl unzip xz-utils nsis wine
	# Download node and Python for windows
	curl --fail --show-error --silent --location --compressed --remote-name https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz
	curl --fail --show-error --silent --location --compressed --remote-name https://www.python.org/ftp/python/${PYTHON_VERSION}/python-${PYTHON_VERSION}-amd64.zip
	sha256sum --check --ignore-missing SHA256SUMS.txt
	# Install node
	tar --extract --xz --file node-v${NODE_VERSION}-linux-x64.tar.xz --directory /usr/local --strip-components=1 --no-same-owner
    ln --symbolic /usr/local/bin/node /usr/local/bin/nodejs
	# 'Install' Python from zip. No messy .exe installs with xvfb etc
	mkdir -p ${WINEPREFIX}/drive_c/Python
	unzip python-${PYTHON_VERSION}-amd64.zip -d ${WINEPREFIX}/drive_c/Python
	# Remove no-longer-needed packages
	apt-get remove -y curl unzip xz-utils
	apt-get clean
	rm -rf /var/lib/apt/lists/*
	rm -rf /tmp/*
EOF


# NOTE: this pip upgrade (if successful) also creates missing pip.exe
RUN <<EOF
	wine python -m pip install --upgrade pip; wineserver -w
	wine pip install pyinstaller==${PYINSTALLER_VERSION}; wineserver -w
	rm -rf /tmp/*
EOF
