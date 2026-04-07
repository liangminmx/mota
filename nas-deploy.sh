#!/bin/bash

# 魔塔游戏NAS部署脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== 魔塔游戏NAS部署 ===${NC}"

# 检查Docker和docker-compose
echo -e "\n${GREEN}1. 检查Docker环境...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker未安装${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker已安装${NC}"

if ! command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}⚠ docker-compose未安装，尝试使用docker compose${NC}"
    if ! docker compose version &> /dev/null; then
        echo -e "${RED}✗ 未找到docker compose${NC}"
        exit 1
    fi
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi
echo -e "${GREEN}✓ docker-compose可用${NC}"

# 检查当前目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [[ ! -f "$SCRIPT_DIR/Dockerfile" ]]; then
    echo -e "${RED}✗ 请在项目根目录运行此脚本${NC}"
    exit 1
fi

# NAS特定配置
echo -e "\n${GREEN}2. NAS环境配置...${NC}"

# 获取本地IP
LOCAL_IP=$(hostname -I 2>/dev/null | cut -d' ' -f1) || LOCAL_IP="127.0.0.1"
echo "  本机IP地址: $LOCAL_IP"

# NAS网络配置建议
read -p "  使用哪个端口? (默认: 8080): " NAS_PORT
NAS_PORT=${NAS_PORT:-8080}

read -p "  容器数据持久化路径? (默认: /vol1/1000/docker/mota): " DATA_PATH
DATA_PATH=${DATA_PATH:-/vol1/1000/docker/mota}

# 创建数据目录
echo "  创建数据目录: $DATA_PATH"
mkdir -p "$DATA_PATH/logs" 2>/dev/null || true
mkdir -p "$DATA_PATH/config" 2>/dev/null || true

# 复制配置文件
echo "  复制配置文件..."
cp -f "$SCRIPT_DIR/docker-compose.yml" "$DATA_PATH/"
cp -f "$SCRIPT_DIR/Dockerfile" "$DATA_PATH/" 2>/dev/null || true
cp -f "$SCRIPT_DIR/nginx.conf" "$DATA_PATH/" 2>/dev/null || true
cp -f "$SCRIPT_DIR/.env" "$DATA_PATH/" 2>/dev/null || true

# 创建NAS特定的.env文件
cat > "$DATA_PATH/.env.nas" << EOF
# NAS魔塔游戏配置
GAME_PORT=$NAS_PORT
NGINX_PORT=80
COMPOSE_PROJECT_NAME=mota-nas

# 数据持久化
LOG_PATH=$DATA_PATH/logs
CONFIG_PATH=$DATA_PATH/config

# 网络设置
LOCAL_IP=$LOCAL_IP
EOF

echo -e "${GREEN}✓ NAS配置文件已创建${NC}"

# 部署选项
echo -e "\n${GREEN}3. 选择部署方式...${NC}"
echo "  1) 使用本地构建（最新源码）"
echo "  2) 使用GitHub镜像（最新发布）"
echo "  3) 使用现有镜像（如果已构建）"
read -p "  请选择 (1/2/3，默认1): " -n 1 -r DEPLOY_MODE
echo

case $DEPLOY_MODE in
    2)
        # 使用GitHub镜像
        echo "  → 使用GitHub镜像部署"
        sed -i "s|build: .|image: ghcr.io/liangminmx/mota:latest|g" "$DATA_PATH/docker-compose.yml"
        ;;
    3)
        # 使用现有镜像
        echo "  → 使用本地现有镜像"
        if docker images | grep -q "mota-game:latest"; then
            sed -i "s|build: .|image: mota-game:latest|g" "$DATA_PATH/docker-compose.yml"
        else
            echo -e "${YELLOW}⚠ 本地镜像不存在，使用构建方式${NC}"
        fi
        ;;
    *)
        # 默认使用本地构建
        echo "  → 使用本地构建"
        # 复制游戏文件
        if [[ -d "$SCRIPT_DIR/mt" ]]; then
            echo "  复制游戏文件..."
            cp -r "$SCRIPT_DIR/mt" "$DATA_PATH/"
        else
            echo -e "${YELLOW}⚠ 游戏文件未找到，从镜像获取${NC}"
        fi
        ;;
esac

# 更新docker-compose.yml中的路径
echo "  更新路径配置..."
sed -i "s|\./logs|$DATA_PATH/logs|g" "$DATA_PATH/docker-compose.yml"
sed -i "s|\./mt|$DATA_PATH/mt|g" "$DATA_PATH/docker-compose.yml" 2>/dev/null || true

# 启动服务
echo -e "\n${GREEN}4. 启动容器服务...${NC}"
cd "$DATA_PATH"
echo "  工作目录: $(pwd)"

# 停止旧容器
echo "  停止旧容器（如果存在）..."
$DOCKER_COMPOSE down 2>/dev/null || true

# 启动新容器
echo "  启动新容器..."
$DOCKER_COMPOSE --env-file .env.nas up -d

sleep 3

# 检查容器状态
echo -e "\n${GREEN}5. 检查部署状态...${NC}"
if $DOCKER_COMPOSE ps | grep -q "Up"; then
    echo -e "${GREEN}✓ 容器启动成功${NC}"
else
    echo -e "${RED}✗ 容器启动失败${NC}"
    $DOCKER_COMPOSE logs --tail=20
    exit 1
fi

# 检查服务可用性
echo "  检查服务响应..."
for i in {1..10}; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$NAS_PORT 2>/dev/null || echo "000")
    if [[ "$HTTP_CODE" == "200" ]]; then
        echo -e "${GREEN}✓ 服务响应正常 (HTTP 200)${NC}"
        break
    elif [[ $i -eq 10 ]]; then
        echo -e "${YELLOW}⚠ 服务未返回200状态码（可能仍在启动）${NC}"
    else
        echo "  第$i次尝试... (状态码: $HTTP_CODE)"
        sleep 2
    fi
done

# 部署完成信息
echo -e "\n${BLUE}=== NAS部署完成 ===${NC}"
echo -e "${GREEN}访问信息:${NC}"
echo "  - 本地访问: http://localhost:$NAS_PORT"
echo "  - 网络访问: http://$LOCAL_IP:$NAS_PORT"
echo "  - 容器名称: mota-nas-mota-game-1"
echo "  - 数据路径: $DATA_PATH"
echo ""
echo -e "${GREEN}管理命令:${NC}"
echo "  # 进入目录"
echo "  cd $DATA_PATH"
echo ""
echo "  # 查看日志"
echo "  $DOCKER_COMPOSE logs -f"
echo ""
echo "  # 停止服务"
echo "  $DOCKER_COMPOSE down"
echo ""
echo "  # 重启服务"
echo "  $DOCKER_COMPOSE restart"
echo ""
echo -e "${YELLOW}注意:${NC}"
echo "  1. 确保防火墙允许端口 $NAS_PORT"
echo "  2. 数据文件存储在 $DATA_PATH"
echo "  3. 访问游戏可能需要等待几秒完全启动"
echo ""
echo -e "${GREEN}部署时间: $(date)${NC}"