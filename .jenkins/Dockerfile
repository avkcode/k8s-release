FROM jenkins/jenkins:lts

USER root

# Install Docker
RUN apt-get update && \
    apt-get -y install apt-transport-https ca-certificates curl gnupg lsb-release && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get -y install docker-ce docker-ce-cli containerd.io

# Install Docker Compose
RUN curl -L "https://github.com/docker/compose/releases/download/v2.24.6/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose && \
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Install package building tools
RUN apt-get update && \
    apt-get -y install dpkg-dev createrepo-c rpm

# Add Jenkins user to the docker group
RUN usermod -aG docker jenkins

USER jenkins

# Install Jenkins plugins
RUN jenkins-plugin-cli --plugins \
    workflow-aggregator \
    git \
    github \
    github-branch-source \
    credentials-binding \
    docker-workflow \
    pipeline-stage-view \
    blueocean \
    parameterized-trigger \
    timestamper
