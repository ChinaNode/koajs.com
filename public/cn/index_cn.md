# 安装

  Koa 当前需要 node 0.11.x 并开启 --harmony (或--harmony-generators), 因为它依赖于 ES6 的 generator 特性. 如果你的当前 Node 版本小于 0.11, 可以通过 [n](https://github.com/visionmedia/n) (node 版本管理工具) 快速安装 0.11.x

````
$ npm install -g n
$ n 0.11.12
$ node --harmony my-koa-app.js
````

  为了方便，可以将 `node` 设置为默认启动 harmony 模式的别名：

````
alias node='node --harmony'
````

  还可以使用 [gnode](https://github.com/TooTallNate/gnode) 运行程序, 但执行效率会较低.

# Application

  Koa 应用是一个包含中间件 generator 方法数组的对象。当请求到来时, 这些方法会以 stack-like 的顺序执行, 从这个角度来看，Koa 和其他中间件系统（比如 Ruby Rack 或者 Connect/Express ）非常相似. 然而 Koa 的一大设计理念是: 通过其他底层中间件层提供高级「语法糖」，而不是Koa. 这大大提高了框架的互操作性和健壮性, 并让中间件开发变得简单有趣.

  比如内容协商（content-negotation）、缓存控制（cache freshness）、反向代理（proxy support）重定向等常见功能都由中间件来实现. 将类似常见任务分离给中间件实现, Koa 实现了异常精简的代码. 


  一如既往的 Hello world:

```js
var koa = require('koa');
var app = koa();

app.use(function *(){
  this.body = 'Hello World';
});

app.listen(3000);
```

**译者注：** 与普通的 function 不同，generator functions 以 `function*` 声明。以这种关键词声明的函数支持 `yield`

## 代码级联（Cascading）

  Koa 中间件以一种更加传统的方式级联起来, 跟你在其他系统或工具中碰到的方式非常相似。
  然而在以往的 Node 开发中, 级联是通过回调实现的, 想要开发用户友好的代码是非常困难的,
  Koa 借助 generators 实现了真正的中间件架构, 与 Connect 实现中间件的方法相对比，Koa 的做法不是简单的将控制权依次移交给一个又一个的方法直到某个结束，Koa 执行代码的方式有点像回形针，用户请求通过中间件，遇到 `yield next` 关键字时，会被传递到下游中间件（downstream），在 `yield next` 捕获不到下一个中间件时，逆序返回继续执行代码（upstream）。

  下边这个简单返回 Hello World 的例子可以很好说明 Koa 的中间件机制：一开始，请求经过 x-response-time 和 logging 中间件，记录了请求的开始时间，然后将控制权 yield 给 response 中间件. 当一个中间件执行 `yield next`时，该方法会暂停执行并把控制权传递给下一个中间件，当没有下一个中间件执行 downstream 的时候，代码将会逆序执行所有流过中间件的 upstream 代码。

```js
var koa = require('koa');
var app = koa();

// x-response-time

app.use(function *(next){
  var start = new Date;
  yield next;
  var ms = new Date - start;
  this.set('X-Response-Time', ms + 'ms');
});

// logger

app.use(function *(next){
  var start = new Date;
  yield next;
  var ms = new Date - start;
  console.log('%s %s - %s', this.method, this.url, ms);
});

// response

app.use(function *(){
  this.body = 'Hello World';
});

app.listen(3000);
```


````
.middleware1 {
  // (1) do some stuff
  .middleware2 {
    // (2) do some other stuff
    .middleware3 {
      // (3) NO next yield !
      // this.body = 'hello world'
    }
    // (4) do some other stuff later
  }
  // (5) do some stuff lastest and return
}
````
上方的伪代码中标注了中间件的执行顺序，看起来是不是有点像 ruby 执行代码块（block）时 yield 的表现了？也许这能帮助你更好的理解 koa 运作的方式。

**译者注：** 更加形象的图可以参考 [Django Middleware](https://docs.djangoproject.com/en/1.6/topics/http/middleware/)

![onion.png](https://raw.github.com/fengmk2/koa-guide/master/onion.png)


## 配置（Settings）

应用配置是 app 实例的属性, 目前支持以下配置:

- app.name 应用名称
- app.env 默认是 __NODE_ENV__ 或者 "development"
- app.proxy 决定了哪些 `proxy header` 参数会被加到信任列表中
- app.subdomainOffset 被忽略的 `.subdomains` 列表，详见下方 api

## app.listen(...)

  一个 Koa 应用跟 HTTP server 不是 1-to-1 关系, 一个或多个 Koa 应用可以被加载到一块
  组成一个更大的包含一个 HTTP server 的应用.

  该方法创建并返回一个 http server, 并且支持传递固定参数
  `Server#listen()`. 具体参数可查看 [nodejs.org](http://nodejs.org/api/http.html#http_server_listen_port_hostname_backlog_callback). 如下为一个监听 `3000` 端口的简单应用:

```js
var koa = require('koa');
var app = koa();
app.listen(3000);
```

  方法 `app.listen(...)` 是一个语法糖, 等价于:

```js
var http = require('http');
var koa = require('koa');
var app = koa();
http.createServer(app.callback()).listen(3000);
```

  这意味着你可以同时支持 HTTP 和 HTTPS, 或在多个地址上使用同一个 app.

```js
var http = require('http');
var koa = require('koa');
var app = koa();
http.createServer(app.callback()).listen(3000);
http.createServer(app.callback()).listen(3001);
```

## app.callback()

  返回一个回调方法能用于 `http.createServer()` 来处理请求，也可以将这个回调函数挂载到 Connect/Express 应用上。

## app.use(function)

  将给定的 function 当做中间件加载到应用中，详见 [中间件](https://github.com/koajs/koa/wiki#middleware) 

## app.keys=

 设置 Cookie 签名密钥。

 这些值会被传递给 [KeyGrip](https://github.com/jed/keygrip) 如果你想自己生成一个实例，也可以这样：

```js
app.keys = ['im a newer secret', 'i like turtle'];
app.keys = new KeyGrip(['im a newer secret', 'i like turtle'], 'sha256');
```

  注意，签名密钥只在配置项 `signed` 参数为真是才会生效：

```js
this.cookies.set('name', 'tobi', { signed: true });
```

## 错误处理（Error Handling）

  除非应用执行环境(__NODE_ENV__)被配置为 `"test"`，Koa 都将会将所有错误信息输出到 stderr. 如果想自定义错误处理逻辑, 可以定义一个「错误事件」来监听 Koa app 中发生的错误：

```js
app.on('error', function(err){
  log.error('server error', err);
});
```

  当 req/res 周期中出现任何错误且无法响应客户端时，Koa 会把 `Context`(上下文) 实例作为第二个参数传递给 error 事件：

```js
app.on('error', function(err, ctx){
  log.error('server error', err, ctx);
});
```

  如果有错误发生, 并且还能响应客户端(即没有数据被写入到 socket), Koa 会返回 500 "Internal Server Error".
  这两种情况都会触发 app-level 的 error 事件, 用于 logging.

