# 安装 koa

  koa 依赖支持 generator 的 Node 环境，准确来说，是 `node >= 0.11.9` 的环境。

````
$ npm install koa
````

  安装完成后，应确保使用 `$ node app.js --harmony` 或(--harmony-generators) 即，harmony 模式运行程序。

  为了方便，可以将 `node` 设置为默认启动 harmony 模式的别名：

````
alias node='node --harmony'
````

  还可以使用 [gnode](https://github.com/TooTallNate/gnode) 运行程序, 但执行效率会较低.

# Application

  一个 Koa Application（以下简称 app）由一系列 generator 中间件组成。按照编码顺序在栈内依次执行，从这个角度来看，Koa app 和其他中间件系统（比如 Ruby Rack 或者 Connect/Express ）没有什么太大差别，不过，从另一个层面来看，Koa 提供了一种基于底层中间件编写「语法糖」的设计思路，这让设计中间件变得更简单有趣。

  在这些中间件中，有负责内容协商（content-negotation）、缓存控制（cache freshness）、反向代理（proxy support）与重定向等等功能的常用中间件（详见 [中间件](#%E4%B8%AD%E9%97%B4%E4%BB%B6middleware) 章节），但如前所述， Koa 内核并不会打包这些中间件，让我们先来看看 Koa 极其简单的 Hello World 应用程序：


  Hello world:

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

  Koa 中间件以一种非常传统的方式级联起来，你可能会非常熟悉这种写法。

  在以往的 Node 开发中，频繁使用回调不太便于展示复杂的代码逻辑，在 Koa 中，我们可以写出真正具有表现力的中间件。与 Connect 实现中间件的方法相对比，Koa 的做法不是简单的将控制权依次移交给一个又一个的中间件直到程序结束，Koa 执行代码的方式有点像回形针，用户请求通过中间件，遇到 `yield next` 关键字时，会被传递到下一个符合请求的路由（downstream），在 `yield next` 捕获不到下一个中间件时，逆序返回继续执行代码（upstream）。

  下边这个例子展现了使用这一特殊方法书写的 Hello World 范例：一开始，用户的请求通过 x-response-time 中间件和 logging 中间件，这两个中间件记录了一些请求细节，然后「穿过」 response 中间件一次，最终结束请求，返回 「Hello World」。

  当程序运行到 `yield next`时，代码流会暂停执行这个中间件的剩余代码，转而切换到下一个被定义的中间件执行代码，这样切换控制权的方式，被称为downstream，当没有下一个中间件执行 downstream 的时候，代码将会逆序执行。

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

在上方的范例代码中，中间件以此被执行的顺序已经在注释中标记出来。你也可以自己尝试运行一下这个范例，并打印记录下各个环节的输出与耗时。

**译者注：** 「级联」这个词许多人也许在 CSS 中听说过，如果你不能理解为什么在这里使用这个词，可以将这种路由结构想象成 LESS 的继承嵌套书写方式：

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


## 应用配置（Settings）

应用的配置是 app 实例的属性。目前来说，Koa 的配置项如下：

- app.name 应用名称
- app.env 执行环境，默认是 `NODE_ENV` 或者 `"development"` 字符串
- app.proxy 决定了哪些 `proxy header` 参数会被加到信任列表中
- app.subdomainOffset 被忽略的 `.subdomains` 列表，详见下方 api
- app.jsonSpaces 输出 json 时是否自动添加空格充当缩进，详见下方 api
- app.outputErrors 是否输出错误堆栈（`err.stack`）到 `stderr` [当执行环境是 `"test"` 的时候为 `false`]

## 中间件（Middleware）
* [koa-router](https://github.com/alexmingoia/koa-router)
* [trie-router](https://github.com/koajs/trie-router)
* [route](https://github.com/koajs/route)
* [basic-auth](https://github.com/koajs/basic-auth)
* [etag](https://github.com/koajs/etag)
* [compose](https://github.com/koajs/compose)
* [static](https://github.com/koajs/static)
* [static-cache](https://github.com/koajs/static-cache)
* [session](https://github.com/koajs/session)
* [compress](https://github.com/koajs/compress)
* [csrf](https://github.com/koajs/csrf)
* [logger](https://github.com/koajs/logger)
* [mount](https://github.com/koajs/mount)
* [send](https://github.com/koajs/send)
* [error](https://github.com/koajs/error)


## app.listen(...)

  一个 Koa 应用跟 HTTP server 不是 1-to-1 关系, 一个或多个 Koa 应用可以被加载到一块
  组成一个更大的包含一个 HTTP server 的应用.

  创建并返回一个 http server, 并且支持传递参数
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

  这样你可以同时支持 HTTP 和 HTTPS, 或在多个地址上使用同一个 app.

```js
var http = require('http');
var koa = require('koa');
var app = koa();
http.createServer(app.callback()).listen(3000);
http.createServer(app.callback()).listen(3001);
```

## app.callback()

  返回一个可被 `http.createServer()` 接受的程序实例，也可以将这个返回函数挂载在一个 Connect/Express 应用中。

## app.use(function)

  将给定的 function 当做中间件加载到应用中，详见 [中间件](#middleware) 章节

## app.keys=

 设置一个签名 Cookie 的密钥。这些参数会被传递给 [KeyGrip](https://github.com/jed/keygrip) 如果你想自己生成一个实例，也可以这样：

```js
app.keys = ['im a newer secret', 'i like turtle'];
app.keys = new KeyGrip(['im a newer secret', 'i like turtle'], 'sha256');
```

  注意，签名密钥只在配置项 `signed` 参数为真是才会生效：

```js
this.cookies.set('name', 'tobi', { signed: true });
```

## 错误处理（Error Handling）

  除非应用执行环境被配置为 `"test"`，Koa 都将会将所有错误信息输出到 stderr，和 Connect 一样，你可以自己定义一个「错误事件」来监听 Koa app 中发生的错误：

```js
app.on('error', function(err){
  log.error('server error', err);
});
```

  当任何 req 或者 res 中出现的错误无法被回应到客户端时，Koa 会在第二个参数传入这个错误的上下文：

```js
app.on('error', function(err, ctx){
  log.error('server error', err, ctx);
});
```

  如果任何错误有可能被回应到客户端，比如当没有新数据写入 socket 时，Koa 会默认返回一个 500 错误，并抛出一个 app 级别的错误到日志处理中间件中。


