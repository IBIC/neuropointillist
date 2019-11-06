FROM amazonlinux:latest
RUN yum -y install which unzip aws-cli
RUN amazon-linux-extras install epel
RUN yum -y install  R
COPY docker_install.Rscript /docker_install.Rscript
COPY neuropointillist /neuropointillist
RUN Rscript /docker_install.Rscript
ADD npoint /usr/local/bin/npoint
ADD npointrun /usr/local/bin/npointrun

