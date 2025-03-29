metadata_startup_script = <<EOT
    #!/bin/bash
    set -e
    exec > >(tee /var/log/startup-script.log) 2>&1

    echo "Updating system packages..."
    sudo apt update -y && sudo apt install -y curl unzip docker.io

    echo "Enabling and starting Docker..."
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker $(whoami)

    echo "Fetching latest OpenTofu version..."
    TOFU_VERSION=\$(curl -s https://api.github.com/repos/opentofu/opentofu/releases/latest | grep "tag_name" | cut -d '"' -f 4)

    if [ -z "\$TOFU_VERSION" ]; then
      echo "Failed to fetch OpenTofu version. Falling back to default version."
      TOFU_VERSION="1.6.0"
    fi

    # Detect system architecture
    ARCH=\$(uname -m)
    if [ "\$ARCH" == "x86_64" ]; then
      TOFU_ARCH="linux_amd64"
    elif [ "\$ARCH" == "aarch64" ]; then
      TOFU_ARCH="linux_arm64"
    else
      echo "Unsupported architecture: \$ARCH"
      exit 1
    fi

    # Download OpenTofu
    TOFU_URL="https://github.com/opentofu/opentofu/releases/download/\${TOFU_VERSION}/tofu_\${TOFU_ARCH}.zip"
    echo "Downloading OpenTofu from \$TOFU_URL..."
    wget "\$TOFU_URL" -O tofu.zip

    # Extract and install
    unzip tofu.zip
    sudo mv tofu /usr/local/bin/tofu
    sudo chmod +x /usr/local/bin/tofu

    # Verify installation
    tofu --version

    echo "Deploying Harness Delegate using Docker..."
    docker run --cpus=1 --memory=2g \
      -e DELEGATE_NAME="docker-delegate" \
      -e NEXT_GEN="true" \
      -e DELEGATE_TYPE="DOCKER" \
      -e ACCOUNT_ID="axO8S93qRGqqf1tlBaonnQ" \
      -e DELEGATE_TOKEN="OWYyNDYzMjVlODVkZTJlY2RiZmFlZjM2NmEzMDk3N2Y=" \
      -e DELEGATE_TAGS="" \
      -e MANAGER_HOST_
