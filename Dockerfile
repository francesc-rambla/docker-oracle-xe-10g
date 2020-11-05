FROM debian:wheezy

MAINTAINER Francesc Rambla <frambla@gmail.com>

ADD oracle-xe_10.2.0.1-1.1_i386.debaa /
ADD oracle-xe_10.2.0.1-1.1_i386.debab /
ADD oracle-xe_10.2.0.1-1.1_i386.debac /
RUN cat /oracle-xe_10.2.0.1-1.1_i386.deba* > /oracle-xe_10.2.0.1-1.1_i386.deb

# Change sources.list to point archive.debian.org
COPY sources.list /etc/apt
RUN chmod 664 /etc/apt/sources.list
# Install sshd and architecture i386
RUN dpkg --add-architecture i386

# Downgrade libc because to meet libc6-i386 dependencies
COPY *.deb /
RUN dpkg -i  libc-bin_2.13-38+deb7u10_amd64.deb libc6_2.13-38+deb7u10_amd64.deb

# Install and configure dependencies
RUN apt-get update \
  && apt-get -f install \
  && apt-get install -y \
       libc6-i386 \
       libaio1:i386 \
       bc:i386 \
       net-tools \
       openssh-server 
RUN mkdir /var/run/sshd
RUN echo 'root:admin' | chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
RUN echo "export VISIBLE=now" >> /etc/profile

# Install Oracle
RUN dpkg -i /oracle-xe_10.2.0.1-1.1_i386.deb

RUN printf 8080\\n1521\\noracle\\noracle\\ny\\n | /etc/init.d/oracle-xe configure

RUN echo 'export ORACLE_HOME=/usr/lib/oracle/xe/app/oracle/product/10.2.0/server' >> /etc/bash.bashrc
RUN echo 'export LD_LIBRARY_PATH=$ORACLE_HOME/lib' >> /etc/bash.bashrc
RUN echo 'export PATH=$ORACLE_HOME/bin:$PATH' >> /etc/bash.bashrc
RUN echo 'export ORACLE_SID=XE' >> /etc/bash.bashrc

# Remove installation files
RUN rm /*.deb
RUN apt-get clean

EXPOSE 1521 22

CMD sed -i -E "s/HOST = [^)]+/HOST = $HOSTNAME/g" /usr/lib/oracle/xe/app/oracle/product/10.2.0/server/network/admin/listener.ora; \
	service oracle-xe start; \
	/usr/sbin/sshd -D
