#!/bin/bash

set -e

# 函数：检查并安装必要的组件
check_and_install_prerequisites() {
    echo "Checking and installing prerequisites..."

    # 检查并安装 Git
    if ! command -v git &> /dev/null; then
        echo "Git not found. Installing..."
        sudo apt-get update
        sudo apt-get install -y git
    else
        echo "Git is already installed."
    fi

    # 检查并安装 Docker
    if ! command -v docker &> /dev/null; then
        echo "Docker not found. Installing..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        echo "Please log out and log back in to apply Docker group changes."
    else
        echo "Docker is already installed."
    fi

    # 检查并安装 ZeroTier
    # if ! command -v zerotier-cli &> /dev/null; then
    #     echo "ZeroTier not found. Installing..."
    #     curl -s https://install.zerotier.com | sudo bash
    # else
    #     echo "ZeroTier is already installed."
    # fi

    echo "All prerequisites are installed."
}

# 函数：显示菜单并获取用户选择
show_menu() {
    echo "Please select the installation type:"
    echo "1) K3s Master Node"
    echo "2) K3s Worker Node"
    echo "3) Aliyun Server (Nginx Proxy Manager)"
    read -p "Enter your choice (1-3): " choice
}

# 首先检查并安装先决条件
check_and_install_prerequisites

# 显示菜单并获取用户选择
show_menu

# 基于用户选择执行相应的安装
case $choice in
    1)
      if ! command -v kubectl &> /dev/null; then
        echo "Installing K3s master node..."
        bash scripts/k3s_master.sh
        
        # 获取 K3s URL 和 Token
        export K3S_URL="https://$(hostname -I | awk '{print $1}'):6443"
        export K3S_TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)
        
        # # 安装 Keycloak
        # echo "Installing Keycloak..."
        # kubectl apply -f configs/keycloak-deployment.yaml
        
        # 安装 Jenkins
        echo "Installing Jenkins..."
        bash scripts/jenkins_setup.sh
      else
        echo "kubectl is already installed."
      fi
    2)
      if ! command -v kubectl &> /dev/null; then
        echo "Installing K3s worker node..."
        read -p "Enter the K3s master URL: " K3S_URL
        read -p "Enter the K3s token: " K3S_TOKEN
        export K3S_URL
        export K3S_TOKEN
        bash scripts/k3s_agent.sh
      else
        echo "kubectl is already installed."
      fi
      ;;
      
    3)
        echo "Installing Nginx Proxy Manager on Aliyun server..."
        bash scripts/nginx_proxy_manager.sh
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

# 运行测试
echo "Running tests..."
for test in tests/*.sh; do
    bash "$test"
done

echo "Installation complete!"