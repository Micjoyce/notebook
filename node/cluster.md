# cluster

众所周知Node的单线程设计，在多核CPU的及其背景下，我们有什么方法充分的让我们的nodejs程序‘榨干’多核机器的性能呢？

其实从nodejs v0.8开始，Node新增了一个内置模块——“cluster”，其可通过一个父进程启动多个子进程并管理，从实现集群的功能。

## 最小 cluster demo

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

### 常用API

#### cluster.setupMaster([settings])

setupMaster用来改变默认设置，只能被调用一次，调用后，配置会存在且冻结在cluster.settings里。配置只会影响fork时的行为，实际上这些选项就是传给fork用的，有兴趣的同学可以去对照child_process.fork()的参数。

具体有如下选项：

- execArgv Node执行时的变量数组，传递给node（默认为process.execArgv）。
- exec 执行的文件，配置后就不需要像最开始的例子，在代码里require目标文件了（默认为- process.argv[1]）。
- args 传递给worker的变量数组（默认为process.argv.slice(2))）。
- silent 是否禁止打印内容（默认为false）。
- uid 设置进程的用户ID。
- gid 设置进程的组ID。


#### Event: fork和online

当一个新的worker被fork时就会触发fork事件，而在worker启动时才会触发online事件，所以fork先触发，online后触发。

可以在这两个事件的callback里做些初始化的逻辑，也可以在这时向master报告：“我起来了！”。

#### Event: exit

当任何一个worker停掉都会触发exit事件，可以在回调里增加fork动作重启。

通过worker.suicide来判断，worker是意外中断还是主动停止的（在worker中调用kill和disconnect方法，视作suide。）。

#### Event: message

message事件可以用来做master和worker的通信机制。 这里是个例子 。

利用这套机制，可以用来实现不间断重启，代码。

文章最开始的例子有个问题，尤其是运行在生产环境还不够健壮：如果某个worker因为意外“宕机”了，代码并没有任何处理，这时如果我们重启应用又会造成服务中断。利用这些API就可以利用事件监听的方式做相应处理。


## cluster的负载均衡

Node.js v0.11.2+的cluster模块使用了[round-robin](https://en.wikipedia.org/wiki/Round-robin_scheduling)调度算法做负载均衡，新连接由主进程接受，然后由它选择一个可用的worker把连接交出去，说白了就是轮转法。算法很简单，但据官方说法，实测很高效。


注意：在windows平台，默认使用的是IOCP，官方文档说一旦解决了分发handle对象的性能问题，就会改为RR算法（没有时间表。。）

如果想用操作系统指定的算法，可以在fork新worker之前或者setupMaster()之前指定如下代码：

```
cluster.schedulingPolicy = cluster.SCHED_NONE;
```

或者通过环境变量的方式改变

```
export NODE_CLUSTER_SCHED_POLICY="none" # "rr" is round-robin
```

或在启动Node时指定

```
env NODE_CLUSTER_SCHED_POLICY="none" node app.js
```

### 利用nodejs net模块使用自己的算法实现负载均衡

app_worker.js

```
const Koa = require('koa')
const Router = require('koa-router')
const http = require('http')

const app = new Koa()

const router = new Router()

router.get('/', async function (ctx, next) {
  console.log(process.id)
  ctx.body = 'hello world'
})

app.use(router.routes())
app.use(router.allowedMethods())

// app.listen(3000)

const server = http.createServer(app.callback())
// server.listen(0) 正常情况下，这种调用会导致server在随机端口上监听
// 但在cluster模式中，所有工作进程每次调用listen(0)时会收到相同的“随机”端口
// 如果要使用独立端口的话，应该根据工作进程的ID来生成端口号。
server.listen(0, '127.0.0.1')

process.on('message', (message, connection) => {
  if (message !== 'sticky-session:connection') {
    return
  }
  // 主动发送 connection 事件到 http server，建立tcp连接
  // http://nodejs.cn/api/http.html#http_event_connection
  server.emit('connection', connection)
  connection.resume()
})

````

master.js

```
const net = require('net')
const cluster = require('cluster')
const numCpus = require('os').cpus().length

// 保存worker实例
const workers = new Map()

cluster.setupMaster({
  exec: './app_worker.js',
  args: [],
  silent: true // false输入worker的stderr和stdout
})

if (cluster.isMaster) {
  console.log(`主进程 ${process.pid} 正在运行`)

  // 衍生工作进程
  for (let i = 0; i < numCpus; i++) {
    cluster.fork()
  }

  // fork成功
  cluster.on('fork', worker => {
    // 保存worker实例
    workers.set(worker.id, worker)
  })

  // 监听worker断开连接事件
  cluster.on('disconnect', worker => {
    console.log('[master] app_worker#%s:%s disconnect, suicide: %s, state: %s, current workers: %j',
      worker.id, worker.process.pid, worker.exitedAfterDisconnect, worker.state, Object.keys(cluster.workers));
  })
  // 监听worker推出事件
  cluster.on('exit', (workder, code, signal) => {
    console.log(`工作进程 ${workder.process.pid} 已退出, code ${code}, singal: ${signal}`)
    // 此处需要通知master重新fork一个新的进程，保证足够的启动进程
  })

  // 通过net监听3000端口的tcp连接，并随机将connection句柄分发给worker处理。
  // pauseOnConnect 被设置为 true,
  // 那么与连接相关的套接字都会暂停，也不会从套接字句柄读取数据
  // 这样就允许连接在进程之间传递，避免数据被最初的进程读取。
  // 如果想从一个暂停的套接字开始读数据，请调用connection.resume()
  net.createServer({ pauseOnConnect: true }, connection => {
    if (!connection.remoteAddress) {
      connection.close()
    } else {
      // 随机获取worker
      const worker = randomGetWorker()
      worker.send('sticky-session:connection', connection)
    }
  }).listen(3000)
}

// 从workers随机获取一个worker并返回
// 此处为负载均衡策略
// cluster的默认负载均衡策略为 round-robin https://en.wikipedia.org/wiki/Round-robin_scheduling
const randomGetWorker = () => {
  const ids = Array.from(workers.keys())
  const idx = Math.floor(Math.random() * ids.length)
  const id = ids[idx]
  return workers.get(id)
}

```

启动master

```
node master.js
```

参考连接： 

官方文档[https://nodejs.org/dist/latest-v8.x/docs/api/cluster.html](https://nodejs.org/dist/latest-v8.x/docs/api/cluster.html)

http://www.alloyteam.com/2015/08/nodejs-cluster-tutorial/

http://taobaofed.org/blog/2015/11/10/nodejs-cluster-2/

http://taobaofed.org/blog/2015/11/03/nodejs-cluster/