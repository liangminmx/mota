#!/bin/bash

# 魔塔游戏清理脚本

echo "=== 魔塔游戏清理 ==="

# 停止并删除容器
echo "1. 停止并删除容器..."
if docker-compose down 2>/dev/null; then
    echo "  ✓ docker-compose down 执行成功"
else
    echo "  ✗ docker-compose down 执行失败，尝试手动清理"
fi

# 删除镜像
echo "2. 删除Docker镜像..."
IMAGES=$(docker images | grep "mota" | awk '{print $3}')
COUNT=0
for img in $IMAGES; do
    docker rmi -f $img 2>/dev/null && COUNT=$((COUNT+1))
done
echo "  已删除 $COUNT 个游戏镜像"

# 删除网络
echo "3. 清理Docker网络..."
NETWORKS=$(docker network ls | grep "mota" | awk '{print $1}')
for net in $NETWORKS; do
    docker network rm $net 2>/dev/null
done

# 清理未使用的资源
echo "4. 清理未使用的Docker资源..."
docker system prune -f 2>/dev/null

# 检查清理结果
echo "5. 检查清理结果..."
if docker ps -a | grep -q "mota"; then
    echo "  ✗ 仍有魔塔相关的容器存在"
    docker ps -a | grep "mota"
else
    echo "  ✓ 无魔塔相关容器"
fi

if docker images | grep -q "mota"; then
    echo "  ✗ 仍有魔塔相关的镜像存在"
    docker images | grep "mota"
else
    echo "  ✓ 无魔塔相关镜像"
fi

echo ""
echo "=== 清理完成 ==="
echo "注意事项:"
echo "  - 游戏文件 (mt/) 不会被删除"
echo "  - 配置文件不会被删除"
echo "  - 日志文件 (logs/) 不会被删除"
echo ""
echo "如需完全重新安装，请删除以下目录:"
echo "  logs/ - nginx日志目录"