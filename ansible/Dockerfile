FROM python:3.11-slim

LABEL maintainer="DevOps Team"
LABEL description="Ansible controller for CI/CD automation with AWS/LocalStack support"

# Switch to HTTPS repos for better connectivity
RUN sed -i 's|http://deb.debian.org|https://deb.debian.org|g' /etc/apt/sources.list.d/debian.sources 2>/dev/null || \
    sed -i 's|http://deb.debian.org|https://deb.debian.org|g' /etc/apt/sources.list 2>/dev/null || true

# Install system dependencies
RUN apt-get update && apt-get install -y \
    openssh-client \
    sshpass \
    git \
    curl \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Install Ansible and AWS tools
RUN pip install --no-cache-dir \
    ansible==9.1.0 \
    boto3 \
    botocore \
    awscli

# Install Ansible AWS collection
RUN ansible-galaxy collection install amazon.aws community.aws

# Set working directory
WORKDIR /ansible

# Copy ansible files
COPY . .

# Create ansible configuration
RUN mkdir -p /etc/ansible && \
    echo "[defaults]" > /etc/ansible/ansible.cfg && \
    echo "inventory = /ansible/inventory/hosts" >> /etc/ansible/ansible.cfg && \
    echo "host_key_checking = False" >> /etc/ansible/ansible.cfg && \
    echo "retry_files_enabled = False" >> /etc/ansible/ansible.cfg

# Environment variables
ENV ANSIBLE_HOST_KEY_CHECKING=False
ENV ANSIBLE_RETRY_FILES_ENABLED=False
ENV ANSIBLE_SSH_PIPELINING=True

CMD ["tail", "-f", "/dev/null"]
