####### arkcase #######
ARG PUBLIC_REGISTRY="public.ecr.aws"
ARG ARCH="amd64"
ARG OS="linux"

# https://quay.io/repository/keycloak/keycloak?tab=tags
ARG VER="23.0.1-0"
ARG PKG="apache"
#ARG SRC=""

ARG JMX_VER="0.17.0"
ARG JMX_SRC="https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/${JMX_VER}/jmx_prometheus_javaagent-${JMX_VER}.jar"

ARG BASE_REPO="arkcase/base"
ARG BASE_VER="8"
ARG BASE_IMG="${PUBLIC_REGISTRY}/${BASE_REPO}:${BASE_VER}"

#FROM "${SRC}" as builder
FROM "${BASE_IMG}"

#######################
# https://catalog.redhat.com/software/containers/ubi8/ubi/5c359854d70cc534b3a3784e?architecture=amd64&image=6541c6b9f354125509854d4a&container-tabs=dockerfile

ENV container oci
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

CMD ["/bin/bash"]

RUN rm -rf /var/log/*
RUN mkdir -p /var/log/rhsm

#######################


# This image is the base image for all s2i configurable container images.
#FROM registry.stage.redhat.io/ubi8/ubi:8.9

ENV SUMMARY="Base image which allows using of source-to-image."	\
    DESCRIPTION="The s2i-core image provides any images layered on top of it \
with all the tools needed to use source-to-image functionality while keeping \
the image size as small as possible."

LABEL summary="$SUMMARY" \
      description="$DESCRIPTION" \
      io.k8s.description="$DESCRIPTION" \
      io.k8s.display-name="s2i core" \
      io.openshift.s2i.scripts-url=image:///usr/libexec/s2i \
      io.s2i.scripts-url=image:///usr/libexec/s2i \
      com.redhat.component="s2i-core-container" \
      name="ubi8/s2i-core" \
      version="1" \
      com.redhat.license_terms="https://www.redhat.com/en/about/red-hat-end-user-license-agreements#UBI"

ENV \
    # DEPRECATED: Use above LABEL instead, because this will be removed in future versions.
    STI_SCRIPTS_URL=image:///usr/libexec/s2i \
    # Path to be used in other layers to place s2i scripts into
    STI_SCRIPTS_PATH=/usr/libexec/s2i \
    APP_ROOT=/opt/app-root \
    # The $HOME is not set by default, but some applications needs this variable
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
CMD ["base-usage"]

RUN rpm-file-permissions && \
    chown -R 1001:0 ${APP_ROOT}
###### above ubi/ubi8
###### below s2icore #####

ENV SUMMARY="Base image with essential libraries and tools used as a base for \
builder images like perl, python, ruby, etc." \
    DESCRIPTION="The s2i-base image, being built upon s2i-core, provides any \
images layered on top of it with all the tools needed to use source-to-image \
functionality. Additionally, s2i-base also contains various libraries needed for \
it to serve as a base for other builder images, like s2i-python or s2i-ruby." \
    NODEJS_VER=20

LABEL summary="$SUMMARY" \
      description="$DESCRIPTION" \
      io.k8s.description="$DESCRIPTION" \
      io.k8s.display-name="s2i base" \
      com.redhat.component="s2i-base-container" \
      name="ubi8/s2i-base" \
      version="1" \
      com.redhat.license_terms="https://www.redhat.com/en/about/red-hat-end-user-license-agreements#UBI"

# This is the list of basic dependencies that all language container image can
# consume.
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

#FROM ubi8/s2i-base:rhel8.9

# This image provides an Apache+PHP environment for running PHP
# applications.

EXPOSE 8080
EXPOSE 8443

# Description
# This image provides an Apache 2.4 + PHP 7.4 environment for running PHP applications.
# Exposed ports:
# * 8080 - alternative port for http

ENV PHP_VERSION=7.4 \
    PHP_VER_SHORT=74 \
    NAME=php

ENV SUMMARY="Platform for building and running PHP $PHP_VERSION applications" \
    DESCRIPTION="PHP $PHP_VERSION available as container is a base platform for \
building and running various PHP $PHP_VERSION applications and frameworks. \
PHP is an HTML-embedded scripting language. PHP attempts to make it easy for developers \
to write dynamically generated web pages. PHP also offers built-in database integration \
for several commercial and non-commercial database management systems, so writing \
a database-enabled webpage with PHP is fairly simple. The most common use of PHP coding \
is probably as a replacement for CGI scripts."

LABEL summary="${SUMMARY}" \
      description="${DESCRIPTION}" \
      io.k8s.description="${DESCRIPTION}" \
      io.k8s.display-name="Apache 2.4 with PHP ${PHP_VERSION}" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,${NAME},${NAME}${PHP_VER_SHORT},${NAME}-${PHP_VER_SHORT}" \
      io.openshift.s2i.scripts-url="image:///usr/libexec/s2i" \
      io.s2i.scripts-url="image:///usr/libexec/s2i" \
      name="ubi8/${NAME}-${PHP_VER_SHORT}" \
      com.redhat.component="${NAME}-${PHP_VER_SHORT}-container" \
      version="1" \
      com.redhat.license_terms="https://www.redhat.com/en/about/red-hat-end-user-license-agreements#UBI" \
      help="For more information visit https://github.com/sclorg/s2i-${NAME}-container" \
      usage="s2i build https://github.com/sclorg/s2i-php-container.git --context-dir=${PHP_VERSION}/test/test-app ubi8/${NAME}-${PHP_VER_SHORT} sample-server" \
      maintainer="SoftwareCollections.org <sclorg@redhat.com>"

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

RUN yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm 
RUN yum -y install https://rpms.remirepo.net/enterprise/remi-release-8.rpm 
RUN yum -y install yum-utils
RUN yum -y module reset php
RUN yum -y module install php:remi-8.0
#RUN rm /etc/httpd/conf.d/php.conf
#RUN mv /etc/httpd/conf.d/php.conf.rpmnew  /etc/httpd/conf.d/php.conf

# Needed to run apache as root
RUN chmod a+rwx /var/lib/ldap-account-manager/sess
RUN chmod a+rwx /var/lib/ldap-account-manager/tmp
RUN chmod a+rwx /var/lib/ldap-account-manager/config

# Reset permissions of filesystem to default values
RUN /usr/libexec/container-setup && rpm-file-permissions

RUN rm /etc/httpd/conf.d/ssl.conf
RUN chown -R 1001 /var/lib/ldap-account-manager

USER 1001

CMD /usr/libexec/s2i/run

