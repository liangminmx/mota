# 魔塔游戏Docker化 - 基于nginx的静态文件服务
FROM nginx:alpine

# 设置工作目录
WORKDIR /usr/share/nginx/html

# 复制自定义nginx配置
COPY nginx.conf /etc/nginx/nginx.conf

# 复制游戏文件到nginx静态目录
COPY mt/ .

# 创建默认错误页面
RUN echo '<html><head><title>500 Internal Server Error</title></head><body><h1>Internal Server Error</h1><p>游戏服务器出现错误，请稍后重试。</p></body></html>' > /usr/share/nginx/html/50x.html

# 暴露端口
EXPOSE 80

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

# 启动nginx
CMD ["nginx", "-g", "daemon off;"]