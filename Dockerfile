FROM parrotstream/centos-openjdk:8

MAINTAINER jothibasu <zerocool.jothi@gmail.com>

USER root

ENV CDH_VERSION=6.0.0
ENV SPARK_VERSION=2.3.3
ENV SPARK_PACKAGE=spark-$SPARK_VERSION-bin-without-hadoop
ENV SPARK_HOME=/usr/spark-2.3.3
ENV HADOOP_HOME=/usr/lib/hadoop

ADD cloudera-cdh6.repo /etc/yum.repos.d/
RUN rpm --import https://archive.cloudera.com/cdh6/$CDH_VERSION/redhat7/yum/RPM-GPG-KEY-cloudera
RUN yum install -y hadoop-hdfs-namenode hadoop-hdfs-datanode hadoop-yarn-resourcemanager hadoop-yarn-nodemanager hadoop-mapreduce-historyserver
RUN yum clean all

ADD https://archive.apache.org/dist/spark/spark-$SPARK_VERSION/$SPARK_PACKAGE.tgz /tmp/
RUN tar -zxvf /tmp/$SPARK_PACKAGE.tgz -C /tmp && \
    mv /tmp/$SPARK_PACKAGE $SPARK_HOME && \
    rm -rf $SPARK_HOME/examples $SPARK_HOME/ec2 /tmp/$SPARK_PACKAGE.tgz && \
    chown -R hadoop:hadoop $SPARK_HOME

RUN mkdir -p /var/run/hdfs-sockets; \
    chown hdfs.hadoop /var/run/hdfs-sockets
RUN mkdir -p /data/dn/
RUN chown hdfs.hadoop /data/dn

RUN useradd -m -u 1000 -g hadoop hadoop

ADD etc/supervisord.conf /etc/
ADD etc/hadoop/conf/core-site.xml /etc/hadoop/conf/
ADD etc/hadoop/conf/hdfs-site.xml /etc/hadoop/conf/
ADD etc/hadoop/conf/mapred-site.xml /etc/hadoop/conf/

WORKDIR /

RUN yum install -y sudo

ENV SPARK_DIST_CLASSPATH=$(/usr/lib/hadoop/bin/hadoop classpath)
ENV PATH=$PATH:$SPARK_HOME/bin
ENV HADOOP_INSTALL=/usr/lib/hadoop
ENV HADOOP_CONF_DIR=$HADOOP_INSTALL/etc/hadoop

# Various helper scripts
ADD bin/start-hdfs.sh ./
ADD bin/start-yarn.sh ./
ADD bin/supervisord-bootstrap.sh ./
ADD bin/wait-for-it.sh ./
RUN chown hadoop:hadoop ./*.sh && \
	chmod +x ./*.sh && \
	chown hadoop:hadoop /etc/supervisord.conf

RUN chown mapred:mapred /var/log/hadoop-mapreduce

EXPOSE 50010 50020 50070 50075 50090 50091 50100 50105 50475 50470 8020 8485 8480 8481
EXPOSE 50030 50060 13562 10020 19888
EXPOSE 8030 8031 8032 8040 8042 8046 8047 8088 8090 8188 8190 8788 10200

USER hadoop

ENTRYPOINT ["supervisord", "-c", "/etc/supervisord.conf", "-n"]
