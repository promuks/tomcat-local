FROM tomcat:8.0.15-jre8

#RUN mkdir -p /usr/local/tomcat/db2 /usr/local/tomcat/mq /usr/local/tomcat/wasejb

############################################################################################################################


# Install build tools on top of base image
# Java jdk 8, Maven 3.3, Gradle 2.6
ENV GRADLE_VERSION 2.6
ENV MAVEN_VERSION 3.3.3

RUN yum install -y --enablerepo=centosplus \
    tar unzip bc which lsof java-1.8.0-openjdk java-1.8.0-openjdk-devel && \
    yum clean all -y && \
    (curl -0 http://www.eu.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | \
    tar -zx -C /usr/local) && \
    mv /usr/local/apache-maven-$MAVEN_VERSION /usr/local/maven && \
    ln -sf /usr/local/maven/bin/mvn /usr/local/bin/mvn && \
    curl -sL -0 https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -o /tmp/gradle-${GRADLE_VERSION}-bin.zip && \
    unzip /tmp/gradle-${GRADLE_VERSION}-bin.zip -d /usr/local/ && \
    rm /tmp/gradle-${GRADLE_VERSION}-bin.zip && \
    mv /usr/local/gradle-${GRADLE_VERSION} /usr/local/gradle && \
    ln -sf /usr/local/gradle/bin/gradle /usr/local/bin/gradle && \
    mkdir -p /opt/openshift && \
    mkdir -p /opt/app-root/source && chmod -R a+rwX /opt/app-root/source && \
    mkdir -p /opt/s2i/destination && chmod -R a+rwX /opt/s2i/destination && \
    mkdir -p /opt/app-root/src && chmod -R a+rwX /opt/app-root/src



ENV PATH=/opt/maven/bin/:/opt/gradle/bin/:$PATH


ENV BUILDER_VERSION 1.0

LABEL io.k8s.description="Platform for building Spring Boot applications with maven or gradle" \
      io.k8s.display-name="Spring Boot builder 1.0" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,maven-3,gradle-2.6,springboot"

# TODO (optional): Copy the builder files into /opt/openshift
# COPY ./<builder_folder>/ /opt/openshift/
# COPY Additional files,configurations that we want to ship by default, like a default setting.xml

LABEL io.openshift.s2i.scripts-url=image:///usr/local/sti
COPY ./.sti/bin/ /usr/local/sti

RUN chown -R 1001:1001 /opt/openshift

# This default user is created in the openshift/base-centos7 image
USER 1001

#######################################################################################################################

RUN set -x \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		vim \
		wget \
		curl \		
	&& rm -rf /var/lib/apt/lists/*
	
ADD conf /usr/local/tomcat/conf
ADD lib /usr/local/tomcat/lib
ADD properties /usr/local/tomcat/properties

ADD bin /usr/local/tomcat/bin
ADD cert /usr/local/tomcat/certs


#ADD db2 /usr/local/tomcat/db2
#ADD mq /usr/local/tomcat/mq
#ADD wasejb /usr/local/tomcat/wasejb

ADD webapps /usr/local/tomcat/webapps

# Drop the root user and make the content of /opt/app-root owned by user 1001
RUN chown -R 1001:0 /usr/local/tomcat

RUN chmod -R ug+rw /usr/local/tomcat

RUN chmod -R ug+rwx /usr/local/tomcat/bin/addldapcert.sh

RUN /usr/local/tomcat/bin/addldapcert.sh

# Set the default user for the image, the user itself was created in the base image
USER 1001


EXPOSE 8052

CMD ["catalina.sh", "run"]
