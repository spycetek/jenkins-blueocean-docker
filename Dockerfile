FROM jenkinsci/blueocean:1.18.1

ARG http_port=8080
ARG agent_port=50000

USER root
WORKDIR /tmp

RUN apk update


# Install MySQL client as root user
RUN apk add --no-cache mysql-client


# Install pip for AWS CLI as root user
RUN apk add --no-cache python
RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py

# Install AWS CLI tool as root user
RUN pip install awscli --upgrade


# Install AWS ECS CLI tool as root user
RUN curl -o /usr/local/bin/ecs-cli https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-amd64-latest && \
    chmod a+x /usr/local/bin/ecs-cli


# Install dependencies for AWS EB CLI tools
RUN apk add --no-cache \
    alpine-sdk autoconf automake libtool linux-headers \
    zlib-dev libffi-dev openssl-dev readline-dev bzip2-dev

# Install AWS EB CLI tool as jenkins user
# EB CLI is installed to `jenkins` user's home directory, which is declared as
# a volume in parent Docker image (jenkins/jenkins).
# This means that any changes to this directory will be discarded.
# So, we move the installed files to /tmp directory, and let the script set to
# ENTRYPOINT to restore files to the home directory after the container is up.
USER jenkins
RUN git clone https://github.com/aws/aws-elastic-beanstalk-cli-setup.git
RUN ./aws-elastic-beanstalk-cli-setup/scripts/bundled_installer && \
    mkdir -p /tmp/jenkins_home_contents && \
    mv /var/jenkins_home/.cache /tmp/jenkins_home_contents/ && \
    mv /var/jenkins_home/.ebcli-virtual-env /tmp/jenkins_home_contents/ && \
    mv /var/jenkins_home/.pyenv /tmp/jenkins_home_contents/ && \
    mv /var/jenkins_home/.pyenv-repository /tmp/jenkins_home_contents/
ENV PATH /var/jenkins_home/.pyenv/versions/3.7.2/bin:$PATH
ENV PATH /var/jenkins_home/.ebcli-virtual-env/executables:$PATH


# Original entry point script + commands to put jenkins_home stuff back.
USER root
COPY jenkins_extd.sh /usr/local/bin/jenkins_extd.sh
RUN chmod a+x /usr/local/bin/jenkins_extd.sh

USER jenkins
WORKDIR /var/jenkins_home

# Redeclaration of EXPOSE and ENTRYPOINT, the same as the original jenkins image.
EXPOSE ${http_port}
EXPOSE ${agent_port}
ENTRYPOINT ["/usr/local/bin/jenkins_extd.sh"]
