FROM python:3.11-slim

LABEL maintainer="DevOps Team"
LABEL description="Ansible controller for CI/CD automation with AWS/LocalStack support"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    openssh-client \
    sshpass \
    git \
    curl \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Install Ansible and AWS collections
RUN pip install --no-cache-dir \
    ansible==9.1.0 \
    boto3 \
    botocore \
    awscli

# Install Ansible AWS collection
RUN ansible-galaxy collection install amazon.aws community.aws

# Set working directory
WORKDIR /ansible

# Create necessary directories
COPY . .

# Create default ansible configuration
RUN echo "[defaults]" > /etc/ansible/ansible.cfg && \
    echo "inventory = /ansible/inventory/hosts" >> /etc/ansible/ansible.cfg && \
    echo "host_key_checking = False" >> /etc/ansible/ansible.cfg && \
    echo "retry_files_enabled = False" >> /etc/ansible/ansible.cfg

# Set environment variables
ENV ANSIBLE_HOST_KEY_CHECKING=False
ENV ANSIBLE_RETRY_FILES_ENABLED=False
ENV ANSIBLE_SSH_PIPELINING=True

CMD ["tail", "-f", "/dev/null"]
