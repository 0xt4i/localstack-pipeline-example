# Jenkins JDK 17, JDK 11 is being deprecated
FROM jenkins/jenkins:latest-jdk17

USER root

# Install dependencies with retry logic and better error handling
RUN apt-get update --fix-missing || apt-get update --fix-missing && \
    apt-get install -y --no-install-recommends \
    lsb-release \
    curl \
    gnupg \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
    https://download.docker.com/linux/debian $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && apt-get install -y docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

# Set timezone
RUN apt-get update && apt-get install -y --no-install-recommends tzdata && \
    rm -rf /var/lib/apt/lists/*

ENV TZ="Asia/Ho_Chi_Minh"

USER jenkins