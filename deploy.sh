#!/bin/bash

# 魔塔游戏Docker部署脚本

set -e

echo "=== 魔塔游戏Docker部署 ==="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: Docker未安装，请先安装Docker${NC}"
    echo "安装指南: https://docs.docker.com/get-docker/"
    exit 1
fi

# 检查docker-compose是否安装
if ! command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}警告: docker-compose未安装，尝试使用docker compose${NC}"
    if ! docker compose version &> /dev/null; then
        echo -e "${RED}错误: docker compose也不可用，请安装docker-compose${NC}"
        echo "安装指南: https://docs.docker.com/compose/install/"
        exit 1
    fi
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

# 检查端口占用
PORT=${GAME_PORT:-8080}
if ss -tuln | grep -q ":${PORT} "; then
    echo -e "${YELLOW}警告: 端口 ${PORT} 已被占用${NC}"
    echo "请修改 .env 文件中的 GAME_PORT 变量或停止占用该端口的服务"
    read -p "是否继续？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 创建日志目录
mkdir -p logs

# 构建镜像
echo -e "\n${GREEN}1. 构建Docker镜像...${NC}"
$DOCKER_COMPOSE build --no-cache

if [ $? -ne 0 ]; then
    echo -e "${RED}构建失败，请检查错误信息${NC}"
    exit 1
fi

# 启动容器
echo -e "\n${GREEN}2. 启动游戏容器...${NC}"
$DOCKER_COMPOSE up -d

if [ $? -ne 0 ]; then
    echo -e "${RED}启动失败，请检查错误信息${NC}"
    exit 1
fi

# 等待服务启动
echo -e "\n${GREEN}3. 等待服务启动...${NC}"
sleep 5

# 检查服务状态
CONTAINER_NAME=${COMPOSE_PROJECT_NAME:-mota-game}
if docker ps --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Status}}" | grep -q "${CONTAINER_NAME}"; then
    echo -e "${GREEN}✓ 容器正在运行${NC}"
else
    echo -e "${RED}✗ 容器未运行，查看日志：${NC}"
    $DOCKER_COMPOSE logs
    exit 1
fi

# 检查健康状态
echo -e "\n${GREEN}4. 检查服务健康状态...${NC}"
if docker inspect --format='{{.State.Health.Status}}' "${CONTAINER_NAME}" | grep -q "healthy"; then
    echo -e "${GREEN}✓ 服务健康检查通过${NC}"
else
    echo -e "${YELLOW}⚠ 服务健康检查未通过，等待重试...${NC}"
    sleep 10
    if docker inspect --format='{{.State.Health.Status}}' "${CONTAINER_NAME}" | grep -q "healthy"; then
        echo -e "${GREEN}✓ 服务健康检查通过${NC}"
    else
        echo -e "${YELLOW}⚠ 健康检查仍然失败，但容器正在运行${NC}"
        echo "查看详细日志: $DOCKER_COMPOSE logs"
    fi
fi

# 测试访问
echo -e "\n${GREEN}5. 测试游戏访问...${NC}"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:${PORT} | grep -q "200"; then
    echo -e "${GREEN}✓ 游戏服务可访问${NC}"
else
    echo -e "${YELLOW}⚠ 游戏服务访问测试失败，但容器正在运行${NC}"
fi

echo ""
echo -e "${GREEN}=== 部署完成 ===${NC}"
echo ""
echo -e "${GREEN}游戏信息：${NC}"
echo "  访问地址: http://localhost:${PORT}"
echo "  容器名称: ${CONTAINER_NAME}"
echo "  网络名称: mota-network"
echo "  日志目录: ./logs"
echo ""
echo -e "${GREEN}管理命令：${NC}"
echo "  停止游戏: $DOCKER_COMPOSE down"
echo "  查看日志: $DOCKER_COMPOSE logs -f"
echo "  重启游戏: $DOCKER_COMPOSE restart"
echo "  进入容器: docker exec -it ${CONTAINER_NAME} sh"
echo ""
echo -e "${GREEN}配置说明：${NC}"
echo "  修改端口: 编辑 .env 文件中的 GAME_PORT 变量"
echo "  查看容器状态: docker ps | grep mota"
echo ""
echo -e "${YELLOW}注意：${NC}"
echo "  游戏为纯前端实现，游戏进度保存在浏览器localStorage中"
echo "  不同浏览器/设备间的游戏进度不共享"