# Request

  Koa `Request` 对象是 node 普通 request 对象之上的抽象, 提供了日常 HTTP server 中有用的功能.

## API

### req.header

  请求头对象.

### req.method

  请求方法.

### req.method=

  设置请求方法, 实现中间件时非常有用, 例如 `methodOverride()`.

### req.length

  将请求的 Content-Length 返回为数字, 或 `undefined`.

### req.url

  获取请求 URL.

### req.url=

设置请求 URL, 在 rewrites 时有用.

### req.path

  获取请求 pathname.

### req.path=

  设置请求 pathname, 如果有 query-string 则保持不变.

### req.querystring

  获取原始 query string, 不包含 `?`.

### req.querystring=

  设置 query string.

### req.search
  
  获取原始 query string, 包含 `?`.

### req.search=

  设置 query string.

### req.host

  获取 host, 不包含端口号. 当 `app.proxy` 为 __true__ 时支持 `X-Forwarded-Host`, 否者就使用 `Host`. 

### req.host=

  设置 `Host` 头字段.

### req.type

  获取请求 `Content-Type` 字段, 不包含参数, 如 "charset".

```js
var ct = this.type;
// => "image/png"
```

### req.charset
  获取请求 charset, 没有返回 `undefined`

### req.query

  获取解析后的 query-string, 如果没有返回空对象. 注意: 该方法不支持嵌套解析.

  例如 "color=blue&size=small":

```js
{
  color: 'blue',
  size: 'small'
}
```

### req.query=

  根据给定的对象设置 query-string. 注意: 该方法不支持嵌套对象.

```js
this.query = { next: '/login' };
```

### req.fresh

  检查请求缓存是否是 "fresh" 的, 即内容没有发生变化. 该方法用于在`If-None-Match` / `ETag`, `If-Modified-Since`, `Last-Modified` 之间进行缓存 negotiation. 这个应该在设置过这些响应 hearder 后会用到.

```js
this.set('ETag', '123');

// cache is ok
if (this.fresh) {
  this.status = 304;
  return;
}

// cache is stale
// fetch new data
this.body = yield db.find('something');
```

### req.stale

  相反与 `req.fresh`.

### req.protocol

  返回请求协议, "https" 或 "http". 当 `app.proxy` 为 __true__ 时支持 `X-Forwarded-Proto`.

### req.secure

  简化版 `this.protocol == "https"` 用于检查请求是否通过 TLS 发送.

### req.ip

  请求 IP 地址. 当 `app.proxy` 为 __true__ 时支持 `X-Forwarded-Proto`.

### req.ips

  当 `X-Forwarded-For` 存在并且 `app.proxy` 开启会返回一个有序(upstream -> downstream)的 ip 数组.
  否则返回空数组.

### req.subdomains

  以数组形式返回子域名.

  子域名是 host 逗号分隔主域名前面的部分. 默认主域名是 host 的最后两部分. 可以通过设置 `app.subdomainOffset` 调整.

  例如, 架设域名是 "tobi.ferrets.example.com":
  如果 `app.subdomainOffset` 没有设置, this.subdomains 为 `["ferrets", "tobi"]`.
  如果 `app.subdomainOffset` 设为 3, this.subdomains 为 `["tobi"]`.

### req.is(type)

  检查请求是否包含 "Content-Type" 字段, 并且包含当前已知的 mime 'type'.
  如果没有请求 body, 返回 `undefined`.
  如果没有字段, 或不包含, 返回 `false`.
  否则返回包含的 content-type.

```js
// With Content-Type: text/html; charset=utf-8
this.is('html'); // => 'html'
this.is('text/html'); // => 'text/html'
this.is('text/*', 'text/html'); // => 'text/html'

// When Content-Type is application/json
this.is('json', 'urlencoded'); // => 'json'
this.is('application/json'); // => 'application/json'
this.is('html', 'application/*'); // => 'application/json'

this.is('html'); // => false
```

  例如, 如果你想确保指定的路由只返回图片.

```js
if (this.is('image/*')) {
  // process
} else {
  this.throw(415, 'images only!');
}
```

### req.accepts(types)

  检查给定的 `type(s)` 是否 acceptable, 如果是, 则返回最佳的匹配, 否则 `false`, 
  这时应该响应 406 "Not Acceptable".

  `type` 值应该是一个或多个 mime 字符串, 例如 "application/json", 扩展名如 "json", 或数组 `["json", "html", "text/plain"]`.
  如果给定一个 list 或 array, 会返回最佳(_best_)匹配项.

  如果请求 client 没有发送 `Accept` header, 会返回第一个 `type`.

```js
// Accept: text/html
this.accepts('html');
// => "html"

// Accept: text/*, application/json
this.accepts('html');
// => "html"
this.accepts('text/html');
// => "text/html"
this.accepts('json', 'text');
// => "json"
this.accepts('application/json');
// => "application/json"

// Accept: text/*, application/json
this.accepts('image/png');
this.accepts('png');
// => undefined

// Accept: text/*;q=.5, application/json
this.accepts(['html', 'json']);
this.accepts('html', 'json');
// => "json"
```

  `this.accepts()` 可以被多次调用, 或使用在 switch.

```js
switch (this.accepts('json', 'html', 'text')) {
  case 'json': break;
  case 'html': break;
  case 'text': break;
  default: this.throw(406);
}
```

### req.acceptsEncodings(encodings)

  检查 `encodings` 是否被接受, 如果是返回最佳匹配, 否则返回 `identity`.

```js
// Accept-Encoding: gzip
this.acceptsEncodings('gzip', 'deflate');
// => "gzip"

this.acceptsEncodings(['gzip', 'deflate']);
// => "gzip"
```

  如果没有传递参数, 会返回所有可接受的 encodings 数组.

```js
// Accept-Encoding: gzip, deflate
this.acceptsEncodings();
// => ["gzip", "deflate"]
```

### req.acceptsCharsets(charsets)

  检查 `charsets` 是否被接受, 如果是返回最佳匹配, 否则 `undefined`.

```js
// Accept-Charset: utf-8, iso-8859-1;q=0.2, utf-7;q=0.5
this.acceptsCharsets('utf-8', 'utf-7');
// => "utf-8"

this.acceptsCharsets(['utf-7', 'utf-8']);
// => "utf-8"
```

  如果没有传递参数, 会返回所有可接受 charsets 数组.

```js
// Accept-Charset: utf-8, iso-8859-1;q=0.2, utf-7;q=0.5
this.acceptsCharsets();
// => ["utf-8", "utf-7", "iso-8859-1"]
```

### req.acceptsLanguages(langs)

  检查 `langs` 是否被接受, 如果是返回最佳匹配, 否则返回 `undefined`.

```js
// Accept-Language: en;q=0.8, es, pt
this.acceptsLanguages('es', 'en');
// => "es"

this.acceptsLanguages(['en', 'es']);
// => "es"
```

  如果没有传递参数, 会返回所有可接受的 lang 数组.

```js
// Accept-Language: en;q=0.8, es, pt
this.acceptsLanguages();
// => ["es", "pt", "en"]
```

### req.idempotent

  判断请求是否是 idempotent.

### req.socket

  返回请求 socket.

### req.get(field)

  返回请求 header.

