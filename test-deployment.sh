#!/bin/bash

# 魔塔游戏部署测试脚本
set -e

echo "=== 魔塔游戏部署测试 ==="

# 检查必需文件
echo "1. 检查必需文件..."
REQUIRED_FILES=("Dockerfile" "docker-compose.yml" "nginx.conf" "mt/index.html")
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ] || [ -d "$(dirname "$file")" ]; then
        echo "  ✓ $file 存在"
    else
        echo "  ✗ $file 缺失"
        exit 1
    fi
done

# 检查mt目录内容
echo "2. 检查游戏文件..."
if [ -d "mt" ]; then
    GAME_FILES=($(ls mt/ | head -10))
    echo "  游戏文件数量: $(find mt -type f | wc -l)"
    echo "  主要文件: ${GAME_FILES[@]}"
else
    echo "  ✗ mt目录不存在"
    exit 1
fi

# 测试Docker构建
echo "3. 测试Docker构建..."
if docker build -t mota-test-build .; then
    echo "  ✓ Docker构建成功"
    
    # 运行测试容器
    echo "4. 测试容器运行..."
    docker run -d -p 8081:80 --name mota-test-run mota-test-build 2>/dev/null
    
    sleep 3
    
    if docker ps | grep -q mota-test-run; then
        echo "  ✓ 容器启动成功"
        
        # 测试HTTP访问
        echo "5. 测试HTTP访问..."
        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8081)
        if [ "$RESPONSE" = "200" ]; then
            echo "  ✓ HTTP访问成功 (状态码: $RESPONSE)"
            
            # 检查HTML内容
            TITLE=$(curl -s http://localhost:8081 | grep -o '<title>[^<]*</title>')
            echo "  ✓ 页面内容检查通过 (标题: $TITLE)"
        else
            echo "  ✗ HTTP访问失败 (状态码: $RESPONSE)"
        fi
        
        # 清理测试容器
        docker stop mota-test-run 2>/dev/null
        docker rm mota-test-run 2>/dev/null
    else
        echo "  ✗ 容器启动失败"
    fi
    
    # 清理测试镜像
    docker rmi mota-test-build 2>/dev/null
else
    echo "  ✗ Docker构建失败"
fi

echo ""
echo "=== 部署测试完成 ==="
echo "建议:"
echo "  1. 运行 ./deploy.sh 进行完整部署"
echo "  2. 访问 http://localhost:8080 验证部署"
echo "  3. 检查 ./logs 目录查看nginx日志"