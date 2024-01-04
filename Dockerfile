####### arkcase #######
ARG PUBLIC_REGISTRY="public.ecr.aws"
ARG ARCH="amd64"
ARG OS="linux"
ARG VER="23.0.1-0"
ARG PKG="apache"

#ARG JMX_VER="0.17.0"
#ARG JMX_SRC="https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/${JMX_VER}/jmx_prometheus_javaagent-${JMX_VER}.jar"

ARG BASE_REPO="arkcase/base"
ARG BASE_VER="8"
ARG BASE_IMG="${PUBLIC_REGISTRY}/${BASE_REPO}:${BASE_VER}"

FROM "${BASE_IMG}"

ENV container oci
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# CMD ["/bin/bash"]

RUN rm -rf /var/log/* && \
    mkdir -p /var/log/rhsm

ENV \
    STI_SCRIPTS_URL=image:///usr/libexec/s2i \
    STI_SCRIPTS_PATH=/usr/libexec/s2i \
    APP_ROOT=/opt/app-root \
    HOME=/opt/app-root/src \
    PATH=/opt/app-root/src/bin:/opt/app-root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    PLATFORM="el8"

RUN INSTALL_PKGS="bsdtar \
  findutils \
  groff-base \
  glibc-locale-source \
  glibc-langpack-en \
  gettext \
  rsync \
  scl-utils \
  tar \
  unzip \
  xz \
  yum" && \
  mkdir -p ${HOME}/.pki/nssdb && \
  chown -R 1001:0 ${HOME}/.pki && \
  yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
  rpm -V $INSTALL_PKGS && \
  yum -y clean all --enablerepo='*'

WORKDIR ${HOME}

ENTRYPOINT ["container-entrypoint"]
# CMD ["base-usage"]

RUN rpm-file-permissions && \
    chown -R 1001:0 ${APP_ROOT}
###### above ubi/ubi8
###### below s2icore #####

ENV    NODEJS_VER=20

RUN yum -y module enable nodejs:$NODEJS_VER && \
  INSTALL_PKGS="autoconf \
  automake \
  bzip2 \
  gcc-c++ \
  gd-devel \
  gdb \
  git \
  libcurl-devel \
  libpq-devel \
  libxml2-devel \
  libxslt-devel \
  lsof \
  make \
  mariadb-connector-c-devel \
  openssl-devel \
  patch \
  procps-ng \
  npm \
  redhat-rpm-config \
  sqlite-devel \
  unzip \
  wget \
  which \
  zlib-devel" && \
  yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
  rpm -V $INSTALL_PKGS && \
  node -v | grep -qe "^v$NODEJS_VER\." && echo "Found VERSION $NODEJS_VER" && \
  yum -y clean all --enablerepo='*'

####### above s2core
####### below rhel8/php-74

EXPOSE 8080
EXPOSE 8443

ENV PHP_VERSION=7.4 \
    PHP_VER_SHORT=74 \
    NAME=php

# Install Apache httpd and PHP
ARG INSTALL_PKGS="php php-mysqlnd php-pgsql php-bcmath \
                  php-gd php-intl php-json php-ldap php-mbstring php-pdo \
                  php-process php-soap php-opcache php-xml \
                  php-gmp php-pecl-apcu php-pecl-zip mod_ssl hostname"

RUN yum -y module enable php:$PHP_VERSION 
RUN yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS 
# RUN yum reinstall -y tzdata
RUN yum install -y tzdata
RUN rpm -V $INSTALL_PKGS
RUN php -v | grep -qe "v$PHP_VERSION\." && echo "Found VERSION $PHP_VERSION"
RUN yum -y clean all --enablerepo='*'

ENV PHP_CONTAINER_SCRIPTS_PATH=/usr/share/container-scripts/php/ \
    APP_DATA=${APP_ROOT}/src \
    PHP_DEFAULT_INCLUDE_PATH=/usr/share/pear \
    PHP_SYSCONF_PATH=/etc \
    PHP_HTTPD_CONF_FILE=php.conf \
    HTTPD_CONFIGURATION_PATH=${APP_ROOT}/etc/conf.d \
    HTTPD_MAIN_CONF_PATH=/etc/httpd/conf \
    HTTPD_MAIN_CONF_D_PATH=/etc/httpd/conf.d \
    HTTPD_MODULES_CONF_D_PATH=/etc/httpd/conf.modules.d \
    HTTPD_VAR_RUN=/var/run/httpd \
    HTTPD_DATA_PATH=/var/www \
    HTTPD_DATA_ORIG_PATH=/var/www \
    HTTPD_VAR_PATH=/var

# Copy the S2I scripts from the specific language image to $STI_SCRIPTS_PATH
COPY ./s2i/bin/ $STI_SCRIPTS_PATH

# Copy extra files to the image.
COPY ./root/ /

COPY ldap-account-manager-8.6.RC1-0.fedora.1.noarch.rpm /tmp
RUN dnf install /tmp/ldap-account-manager-8.6.RC1-0.fedora.1.noarch.rpm -y

# php 8 magic
RUN yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
    yum -y install https://rpms.remirepo.net/enterprise/remi-release-8.rpm && \
    yum -y install yum-utils && \
    yum -y module reset php && \
    yum -y module install php:remi-8.0

# Needed to run apache as root or acount outside of 1001 without chown below.
# RUN chmod a+rwx /var/lib/ldap-account-manager/sess
# RUN chmod a+rwx /var/lib/ldap-account-manager/tmp
# RUN chmod a+rwx /var/lib/ldap-account-manager/config

# Reset permissions of filesystem to default values
RUN /usr/libexec/container-setup && rpm-file-permissions && \
    rm /etc/httpd/conf.d/ssl.conf && \
    chown -R 1001 /var/lib/ldap-account-manager

USER 1001

CMD /usr/libexec/s2i/run

