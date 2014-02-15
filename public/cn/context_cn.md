# Context

  Koa 的 Context 把 node 的 request, response 对象包含进一个单独对象, 并提供许多开发 web 应用和 APIs 的有用方法.

  许多访问器和方法直接委托为他们 `ctx.request` 或 `ctx.response` 的
  等价方法, 用于访问方便, 有些是完全相同.

  这些操作在 HTTP server 开发中使用如此频繁, 所以在这里实现.
  而不是更高层次框架 这样中间件中就不需要重复实现这些通用的功能.

  _每个_ 请求会创建自己的 `Context`, 在中间件中作为 receiver 引用, 或通过 `this` 标示符. 如.

```js
app.use(function *(){
  this; // is the Context
  this.request; // is a koa Request
  this.response; // is a koa Response
});
```

## API

  `Context` 详细方法和访问器.

### ctx.req

  Node 的 `request` 对象.

### ctx.res

  Node 的 `response` 对象.

  Bypassing Koa 的 response handling 是 __not supported__. 避免使用如下 node 属性:

- `res.statusCode`
- `res.writeHead()`
- `res.write()`
- `res.end()`

### ctx.request

  koa `Request` 对象.

### ctx.response

  koa `Response` 对象.

### ctx.app

  应用实例引用.

### ctx.cookies.get(name, [options])

  获取名为 `name` 带有 `options` 的 cookie:

 - `signed` 请求cookie应该是signed

注意: koa 使用 [cookies](https://github.com/jed/cookies) 模块, options 被直接传递过去.

### ctx.cookies.set(name, value, [options])

  设置cookie `name` 为 `value` 带有 `options`:

 - `signed` sign cookie 值
 - `expires` cookie 过期 `Date`
 - `path` cookie 路径, 默认 `/'`
 - `domain` cookie 域名
 - `secure` secure cookie
 - `httpOnly` server 才能访问 cookie, 默认 __true__ 

注意: koa 使用 [cookies](https://github.com/jed/cookies) 模块, options 被直接传递过去.

### ctx.throw(msg, [status])

  Helper 方法, 抛出包含 `.status` 属性的错误, 默认为 `500`. 该方法让 Koa 能够合适的响应.
  并且支持如下组合:

```js
this.throw(403)
this.throw('name required', 400)
this.throw(400, 'name required')
this.throw('something exploded')
```

  例如 `this.throw('name required', 400)` 等价于:

```js
var err = new Error('name required');
err.status = 400;
throw err;
```

  注意这些是 user-level 的错误, 被标记为 `err.expose`, 即这些消息可以用于 client 响应,
  而不是 error message 的情况, 因为你不想泄露失败细节.


### ctx.respond

  如不想使用 koa 内置的 response 处理方法, 可以 设置 `this.respond = false;`. 这时你可以自己设置 `res` 对象.

  注意这样使用是不被 Koa 支持的. 这样有可能会破坏 Koa 的中间件和 Koa 本身. 这种用法只是作为一种 hack 方式, 给那些想在 Koa 中间件和方法内使用传统的`fn(req, res)` 一种方式


## Request 别名

  如下访问器和别名同 [Request](#request) 等价:

  - `ctx.header`
  - `ctx.method`
  - `ctx.method=`
  - `ctx.url`
  - `ctx.url=`
  - `ctx.path`
  - `ctx.path=`
  - `ctx.query`
  - `ctx.query=`
  - `ctx.querystring`
  - `ctx.querystring=`
  - `ctx.length`
  - `ctx.host`
  - `ctx.host=`
  - `ctx.fresh`
  - `ctx.stale`
  - `ctx.socket`
  - `ctx.protocol`
  - `ctx.secure`
  - `ctx.ip`
  - `ctx.ips`
  - `ctx.subdomains`
  - `ctx.is()`
  - `ctx.accepts()`
  - `ctx.acceptsEncodings()`
  - `ctx.acceptsCharsets()`
  - `ctx.acceptsLanguages()`
  - `ctx.get()`

## Response 别名

  如下访问器和别名同 [Response](#response) 等价:

  - `ctx.body`
  - `ctx.body=`
  - `ctx.status`
  - `ctx.status=`
  - `ctx.length=`
  - `ctx.type`
  - `ctx.type=`
  - `ctx.headerSent`
  - `ctx.redirect()`
  - `ctx.attachment()`
  - `ctx.set()`
  - `ctx.remove()`
  - `ctx.lastModified=`
  - `ctx.etag=`
