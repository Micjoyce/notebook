# wrk http性能测试工具

> wrk 是一个很简单的 http 性能测试工具. 也可以叫做 http benchmark 工具. 只有一个命令行, 就能做很多基本的 http 性能测试

wrk的代码在 github 上. [https://github.com/wg/wrk](https://github.com/wg/wrk)

## 安装

### mac

`brew install wrk`

### Ubuntu/Debian (clean box)

```shell
sudo apt-get install build-essential libssl-dev git -y
git clone https://github.com/wg/wrk.git wrk
cd wrk
sudo make
# move the executable to somewhere in your PATH, ex:
sudo cp wrk /usr/local/bin
```

### CentOS / RedHat / Fedora

```shell
sudo yum groupinstall 'Development Tools'
sudo yum install -y openssl-devel git 
git clone https://github.com/wg/wrk.git wrk
cd wrk
make
# move the executable to somewhere in your PATH
sudo cp wrk /somewhere/in/your/PATH
```

## 命令参数

```
用法: wrk <options> <url>
  Options:
    -c, --connections <N>  Connections to keep open
                            打开的连接数
    -d, --duration    <T>  Duration of test
                            持续时间，时间越长越准确
    -t, --threads     <N>  Number of threads to use
                            开启的进程数
    -s, --script      <S>  Load Lua script file
                            Lua脚本
    -H, --header      <H>  Add header to request
                            添加请求的header
        --latency          Print latency statistics
                            打印响应分布的统计
        --timeout     <T>  Socket/request timeout
                            设置响应超时(2s, 2m, 2h)
                            wrk 默认超时时间是1s
    -v, --version          Print version details
                            答应wrk版本信息
  Numeric arguments may include a SI unit (1k, 1M, 1G)
  Time arguments may include a time unit (2s, 2m, 2h)
```

## 使用方法

`wrk -t12 -c400 -d30s --latency  http://127.0.0.1:8000`

> 上面这句话的意思为：12个进程模拟400个连接，持续时间为30秒，并且打印出响应时间的分布

运行结果：

```
Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    42.10ms   98.36ms   2.00s    98.33%
    Req/Sec     1.06k   284.48     4.20k    74.23%
  Latency Distribution
     50%   26.65ms
     75%   41.39ms
     90%   62.64ms
     99%  374.95ms
  376093 requests in 30.07s, 60.62MB read
  Socket errors: connect 0, read 0, write 0, timeout 81
Requests/sec:  12508.83
Transfer/sec:      2.02MB
```

解释：

```
进程状态        平均值     标准差     最大值   正负一个标准差占比
    响应时间    42.10ms   98.36ms   2.00s   98.33%
    请求/秒     1.06k   284.48     4.20k   74.23%
  响应时间分布：
     50%   26.65ms   50% 在26.65毫秒完成
     75%   41.39ms   75% 在41.39毫秒完成
     90%   62.64ms   90% 在62.64毫秒完成
     99%  374.95ms   99% 在374.95毫秒完成
  30.07s 共发送 376093 个请求, 共读取 60.62MB 数据
  Socket 错误: 连接 0, 读 0, 写 0, 超市 81
请求/秒:  12508.83
获取数据/s:  2.02MB
```

## Lua脚本的使用

POST + header + body

编写Lua脚本

```lua
wrk.method = "POST"  
wrk.body   = "foo=bar&baz=quux"  
wrk.headers["Content-Type"] = "application/x-www-form-urlencoded"
```

使用wrk加载脚本并执行

```shell
wrk -t12 -c400 -d30s --latency --script=post.lua --latency http://127.0.0.1:8000
```

wrk 对象的修改全局只会执行一次

wrk的全局对象如下所示：

```
local wrk = {
   scheme  = "http",
   host    = "localhost",
   port    = nil,
   method  = "GET",
   path    = "/",
   headers = {},
   body    = nil,
   thread  = nil,
}
```

## 用 lua 脚本测试复杂场景

wrk 提供了几个 hook 函数，可以用 lua 来编写一些复杂场景下的测试：

### setup

这个函数在目标 IP 地址已经解析完，并且所有 thread 已经生成，但是还没有开始时被调用，每个线程执行一次这个函数。可以通过 thread:get(name)， thread:set(name, value) 设置线程级别的变量。

### init

每次请求发送之前被调用。可以接受 wrk 命令行的额外参数，通过 -- 指定。

### delay

这个函数返回一个数值，在这次请求执行完以后延迟多长时间执行下一个请求，可以对应 thinking time 的场景。

```lua
-- example script that demonstrates adding a random
-- 10-50ms delay before each request

function delay()
   return math.random(10, 50)
end
```

### request

通过这个函数可以每次请求之前修改本次请求的属性，返回一个字符串，这个函数要慎用， 会影响测试端性能。

### response

每次请求返回以后被调用，可以根据响应内容做特殊处理，比如遇到特殊响应停止执行测试，或输出到控制台等等。

```lua
function response(status, headers, body)  
   if status ~= 200 then  
      print(body)  
      wrk.thread:stop()  
   end  
end  
```

### done

在所有请求执行完以后调用, 一般用于自定义统计结果

```lua
done = function(summary, latency, requests)  
   io.write("------------------------------\n")  
   for _, p in pairs({ 50, 90, 99, 99.999 }) do  
      n = latency:percentile(p)  
      io.write(string.format("%g%%,%d\n", p, n))  
   end  
end  
```

## Lua例子

下面是 wrk 源代码中给出的完整例子: 

```lua
local counter = 1  
local threads = {}  
  
function setup(thread)  
   thread:set("id", counter)  
   table.insert(threads, thread)  
   counter = counter + 1  
end  
  
function init(args)  
   requests  = 0  
   responses = 0  
  
   local msg = "thread %d created"  
   print(msg:format(id))  
end  
  
function request()  
   requests = requests + 1  
   return wrk.request()  
end  
  
function response(status, headers, body)  
   responses = responses + 1  
end  
  
function done(summary, latency, requests)  
   for index, thread in ipairs(threads) do  
      local id        = thread:get("id")  
      local requests  = thread:get("requests")  
      local responses = thread:get("responses")  
      local msg = "thread %d made %d requests and got %d responses"  
      print(msg:format(id, requests, responses))  
   end  
end  
```


### 测试复合场景

可以通过 lua 实现访问多个 url. 
例如这个复杂的 lua 脚本, 随机读取 paths.txt 文件中的 url 列表, 然后访问

```lua
counter = 1  
  
math.randomseed(os.time())  
math.random(); math.random(); math.random()  
  
function file_exists(file)  
  local f = io.open(file, "rb")  
  if f then f:close() end  
  return f ~= nil  
end  
  
function shuffle(paths)  
  local j, k  
  local n = #paths  
  for i = 1, n do  
    j, k = math.random(n), math.random(n)  
    paths[j], paths[k] = paths[k], paths[j]  
  end  
  return paths  
end  
  
function non_empty_lines_from(file)  
  if not file_exists(file) then return {} end  
  lines = {}  
  for line in io.lines(file) do  
    if not (line == '') then  
      lines[#lines + 1] = line  
    end  
  end  
  return shuffle(lines)  
end  
  
paths = non_empty_lines_from("paths.txt")  
  
if #paths <= 0 then  
  print("multiplepaths: No paths found. You have to create a file paths.txt with one path per line")  
  os.exit()  
end  
  
print("multiplepaths: Found " .. #paths .. " paths")  
  
request = function()  
    path = paths[counter]  
    counter = counter + 1  
    if counter > #paths then  
      counter = 1  
    end  
    return wrk.format(nil, path)  
end
```

### 关于 cookie 

有些时候我们需要模拟一些通过 cookie 传递数据的场景. wrk 并没有特殊支持, 可以通过 wrk.headers["Cookie"]="xxxxx"实现. 
下面是在网上找的一个例子, 取 Response的cookie作为后续请求的cookie 

```lua
function getCookie(cookies, name)  
  local start = string.find(cookies, name .. "=")  
  
  if start == nil then  
    return nil  
  end  
  
  return string.sub(cookies, start + #name + 1, string.find(cookies, ";", start) - 1)  
end  
  
response = function(status, headers, body)  
  local token = getCookie(headers["Set-Cookie"], "token")  
    
  if token ~= nil then  
    wrk.headers["Cookie"] = "token=" .. token  
  end  
end  
```


## 总结

wrk 本身的定位不是用来替换 loadrunner 这样的专业性能测试工具的. 其实有这些功能已经完全能应付平时开发过程中的一些性能验证了.