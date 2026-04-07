#!/bin/bash

# 魔塔游戏ARM平台部署脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== 魔塔游戏ARM平台部署 ===${NC}"

# 检测当前架构
echo -e "\n${GREEN}1. 检测系统架构...${NC}"
ARCH=$(uname -m)
KERNEL=$(uname -s)
echo "  系统架构: $ARCH"
echo "  内核类型: $KERNEL"

# 识别具体ARM架构
case $ARCH in
    aarch64|arm64)
        PLATFORM="arm64"
        echo "  ✅ ARM64架构 (64位ARM/Raspberry Pi 3B+/4/5)"
        ;;
    armv7l|armhf)
        PLATFORM="armv7"
        echo "  ✅ ARMv7架构 (32位ARM/Raspberry Pi 2/3/Zero)"
        ;;
    x86_64)
        PLATFORM="amd64"
        echo "  ✅ x86_64架构 (标准PC/服务器)"
        ;;
    *)
        echo -e "${YELLOW}⚠ 未知架构: $ARCH${NC}"
        read -p "  请手动指定架构 (amd64/arm64/armv7/默认: auto): " MANUAL_ARCH
        PLATFORM=${MANUAL_ARCH:-auto}
        ;;
esac

# 检查Docker环境
echo -e "\n${GREEN}2. 检查Docker环境...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker未安装${NC}"
    echo "  在ARM设备上安装Docker："
    echo "  # Raspberry Pi/Debian系"
    echo "  curl -fsSL https://get.docker.com -o get-docker.sh"
    echo "  sudo sh get-docker.sh"
    echo "  sudo usermod -aG docker \$USER"
    exit 1
fi

# 检查Docker多架构支持
echo "  检查Docker多架构支持..."
if docker buildx ls | grep -q "arm"; then
    echo -e "${GREEN}✓ Docker已支持ARM架构${NC}"
else
    echo -e "${YELLOW}⚠ Docker可能未配置ARM支持${NC}"
    echo "  尝试启用ARM架构支持："
    echo "  docker run --rm --privileged multiarch/qemu-user-static --reset -p yes"
fi

# 检测设备类型
echo -e "\n${GREEN}3. 检测ARM设备类型...${NC}"
if [[ -f /proc/device-tree/model ]]; then
    DEVICE_MODEL=$(tr -d '\0' < /proc/device-tree/model)
    echo "  设备型号: $DEVICE_MODEL"
    
    case "$DEVICE_MODEL" in
        *"Raspberry Pi 4"*|*"Raspberry Pi 5"*)
            echo "  ✅ Raspberry Pi 4/5 (推荐使用arm64)"
            RECOMMENDED_PLATFORM="arm64"
            ;;
        *"Raspberry Pi 3"*)
            echo "  ✅ Raspberry Pi 3 (支持arm64/armv7)"
            RECOMMENDED_PLATFORM="arm64"
            ;;
        *"Raspberry Pi 2"*|*"Raspberry Pi Zero"*)
            echo "  ✅ Raspberry Pi 2/Zero (建议使用armv7)"
            RECOMMENDED_PLATFORM="armv7"
            ;;
        *"Orange Pi"*)
            echo "  ✅ Orange Pi系列"
            RECOMMENDED_PLATFORM="arm64"
            ;;
        *"Rock Pi"*)
            echo "  ✅ Rock Pi系列"
            RECOMMENDED_PLATFORM="arm64"
            ;;
        *)
            echo "  ℹ 其他ARM设备"
            RECOMMENDED_PLATFORM="$PLATFORM"
            ;;
    esac
else
    echo "  ℹ 非标准ARM设备或无法检测型号"
    RECOMMENDED_PLATFORM="$PLATFORM"
fi

# 部署选项
echo -e "\n${GREEN}4. 选择ARM部署方式...${NC}"
echo "  1) 使用多架构镜像 (自动选择合适平台)"
echo "  2) 指定架构镜像 (手动选择arm64/armv7)"
echo "  3) 本地构建 (适用于离线环境)"
read -p "  请选择 (1/2/3，默认1): " -n 1 -r DEPLOY_MODE
echo

case $DEPLOY_MODE in
    2)
        read -p "  指定架构类型 (arm64/armv7): " SPECIFIC_ARCH
        if [[ "$SPECIFIC_ARCH" == "arm64" || "$SPECIFIC_ARCH" == "armv7" ]]; then
            IMAGE_TAG="-${SPECIFIC_ARCH}"
            echo "  → 使用指定架构: $SPECIFIC_ARCH"
        else
            echo -e "${YELLOW}⚠ 无效架构，使用多架构镜像${NC}"
            IMAGE_TAG=""
        fi
        ;;
    3)
        echo "  → 本地构建模式"
        echo "  注意：本地构建需要时间和资源"
        read -p "  是否继续？ (y/N): " -n 1 -r BUILD_LOCAL
        echo
        if [[ ! $BUILD_LOCAL =~ ^[Yy]$ ]]; then
            echo "  → 使用多架构镜像替代"
            IMAGE_TAG=""
            DEPLOY_MODE=1
        else
            IMAGE_TAG="-local"
        fi
        ;;
    *)
        echo "  → 使用多架构镜像"
        IMAGE_TAG=""
        ;;
esac

# 端口配置
read -p "  服务端口 (默认: 8080): " SERVICE_PORT
SERVICE_PORT=${SERVICE_PORT:-8080}

# 部署执行
echo -e "\n${GREEN}5. 执行部署...${NC}"

if [[ "$DEPLOY_MODE" == "3" && "$IMAGE_TAG" == "-local" ]]; then
    # 本地构建
    echo "  本地构建ARM镜像..."
    docker build -t mota-game:arm-local .
    
    echo "  启动容器..."
    docker run -d \
        --name mota-game-arm \
        -p ${SERVICE_PORT}:80 \
        --restart unless-stopped \
        mota-game:arm-local
else
    # 使用GitHub镜像
    echo "  拉取多架构镜像..."
    FULL_IMAGE="ghcr.io/liangminmx/mota:latest${IMAGE_TAG}"
    docker pull $FULL_IMAGE
    
    echo "  启动容器..."
    docker run -d \
        --name mota-game-arm \
        -p ${SERVICE_PORT}:80 \
        --restart unless-stopped \
        $FULL_IMAGE
fi

sleep 3

# 验证部署
echo -e "\n${GREEN}6. 验证部署状态...${NC}"
if docker ps | grep -q "mota-game-arm"; then
    echo -e "${GREEN}✓ 容器启动成功${NC}"
    
    # 检查服务状态
    LOCAL_IP=$(hostname -I | cut -d' ' -f1) || LOCAL_IP="127.0.0.1"
    echo "  在ARM设备上访问: http://localhost:${SERVICE_PORT}"
    echo "  在局域网访问: http://${LOCAL_IP}:${SERVICE_PORT}"
    
    # 简单健康检查
    for i in {1..5}; do
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${SERVICE_PORT} 2>/dev/null || echo "000")
        if [[ "$HTTP_CODE" == "200" ]]; then
            echo -e "${GREEN}✓ 服务响应正常 (HTTP 200)${NC}"
            break
        elif [[ $i -eq 5 ]]; then
            echo -e "${YELLOW}⚠ 服务未返回200状态码（可能仍在启动）${NC}"
        else
            echo "  第$i次尝试... (状态码: $HTTP_CODE)"
            sleep 2
        fi
    done
else
    echo -e "${RED}✗ 容器启动失败${NC}"
    docker logs mota-game-arm --tail=20
    exit 1
fi

# ARM优化建议
echo -e "\n${GREEN}7. ARM平台优化建议...${NC}"
cat << EOF
  # 资源限制（推荐ARM设备配置）
  docker update mota-game-arm \
    --cpus 1 \
    --memory 256m \
    --memory-swap 256m
  
  # 性能监控
  docker stats mota-game-arm
  
  # 查看容器内部架构信息
  docker exec mota-game-arm cat /usr/share/nginx/html/build-info.txt
EOF

# 完成信息
echo -e "\n${BLUE}=== ARM部署完成 ===${NC}"
echo -e "${GREEN}部署信息:${NC}"
echo "  容器名称: mota-game-arm"
echo "  访问端口: ${SERVICE_PORT}"
echo "  镜像架构: ${PLATFORM}"
echo "  镜像来源: ${FULL_IMAGE:-ghcr.io/liangminmx/mota:latest}"

echo -e "\n${YELLOW}ARM设备注意事项:${NC}"
echo "  1. ARM设备性能较低，启动可能需要更长时间"
echo "  2. Raspberry Pi建议使用arm64架构以获得更好性能"
echo "  3. 确保设备有足够内存（至少512MB）"
echo "  4. 使用SD卡时注意IO性能限制"

echo -e "\n${GREEN}管理命令:${NC}"
echo "  # 查看容器状态"
echo "  docker ps | grep mota"
echo "  # 查看容器日志"
echo "  docker logs mota-game-arm -f"
echo "  # 停止服务"
echo "  docker stop mota-game-arm && docker rm mota-game-arm"

echo -e "\n${GREEN}部署时间: $(date)${NC}"