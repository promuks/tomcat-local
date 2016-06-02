FROM tomcat:8.0.15-jre8

#RUN mkdir -p /usr/local/tomcat/db2 /usr/local/tomcat/mq /usr/local/tomcat/wasejb

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

#ADD db2 /usr/local/tomcat/db2
#ADD mq /usr/local/tomcat/mq
#ADD wasejb /usr/local/tomcat/wasejb

ADD webapps /usr/local/tomcat/webapps

# Drop the root user and make the content of /opt/app-root owned by user 1001
RUN chown -R 1001:0 /usr/local/tomcat

# Set the default user for the image, the user itself was created in the base image
USER 1001


EXPOSE 8052

CMD ["catalina.sh", "run"]
