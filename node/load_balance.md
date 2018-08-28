# cluster

众所周知Node的单线程设计，在多核CPU的及其背景下，我们有什么方法充分的让我们的nodejs程序‘榨干’多核机器的性能呢？

我了解到的方式有三种：

1. pm2 + nginx
2. kubernetes
3. nodejs cluster

## pm2 + nginx

通过pm2启动多实例，然后交给nginx的upstream配置帮我们把用户的连接分发到各个实例上，从而实现负载均衡。

以下为一个pm2+nginx的demo

> nodejs 程序

app.js
```
const http = require('http')
const port = process.env.PORT || 8080
http.createServer((req, res) => {
  res.end('hello world\n')
}).listen(port)
```

> pm2启动多实例配置

pm2_config.json
```
[{
  "name": "app-1",
  "script": "./app.js",
  "env": {
    "NODE_ENV": "production",
    "PORT: "8080"
  }
}, {
  "name": "app-1",
  "script": "./app.js",
  "env": {
    "NODE_ENV": "production",
    "PORT: "8081"
  }
}]
```

> nginx

```
upstream app.server {
  server localhost:8080 weight=1;
  server localhost:8081 weight=1;
}
server {
    listen 0.0.0.0:80;
    server_name youdomain.com;
    access_log /var/log/nginx/project.log;
    error_log /var/log/nginx/project_err.log;

    location / {
        proxy_pass http://app.server;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
        proxy_set_header X-NginX-Proxy true;
        proxy_http_version 1.1;
        proxy_redirect off;
    }
}
```

虽然以上方法我们可以非常简单的实现一个负载均衡的方案，但是有几个弊端：

1.我们需要监听多个端口

2.分发策略完全由nginx控制，并且需要引入pm2管理启动程序（这个有可能不是问题）

## Kubernetes 容器化负载均衡

待续...

## nodejs cluster

那有没有更好的方法让我们通过nodejs本身就能实现负载均衡？根据cpu和数部署多个实例呢？ 

其实从nodejs v0.8开始，Node新增了一个内置模块——“cluster”，其可通过一个父进程启动多个子进程并管理，从实现集群的功能。

### 最小 cluster demo

```js
const cluster = require('cluster')
const http = require('http')
const numCpus = require('os').cpus().length

if (cluster.isMaster) {
  console.log(`主进程 ${process.pid} 正在运行`)
  // 衍生工作进程
  for (let i = 0; i < numCpus; i++) {
    cluster.fork()
  }
} else {
  http.createServer((req, res) => {
    res.end('hello world\n')
  }).listen(8000)
  console.log(`工作进程 ${process.pid} 已启动`)
}

```

通过isMaster属性，判断是否Master进程，是则fork子进程，否则启动一个server。每个HTTP server都能监听到同一个端口
