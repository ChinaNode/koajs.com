
# Guide

  这节内容跟 API 无关, 而是中间件开发最佳实践, 应用架构建议等.

## 开发中间件

  Koa 中间件是返回 `GeneratorFunction` 的方法, 并接受其他的中间件. 当某个中间件被 "upstream" 中间件执行时, 它必须手动 `yield`
  "downstream" 中间件

  例如你想记录 request 传递经过 Koa 的时间, 可以开发一个添加 `X-Response-Time` 头字段的中间件.

```js
function *responseTime(next){
  var start = new Date;
  yield next;
  var ms = new Date - start;
  this.set('X-Response-Time', ms + 'ms');
}

app.use(responseTime);
```

  如下是一个等价的 inline 中间件:

```js
app.use(function *(next){
  var start = new Date;
  yield next;
  var ms = new Date - start;
  this.set('X-Response-Time', ms + 'ms');
});
```

  如果你是一个前端工程师, 可以把所有 `yield next;` 之前的代码看做 "capture" 阶段, 把之后的代码看做 "bubble" 阶段. 
  如下 gif 展示了 ES6 generators 如何让我们合理的使用 stack flow 实现 request and response flows:

![koa middleware](https://github.com/koajs/koa/raw/master/docs/middleware.gif)

   1. 创建 date 记录花费时间
   2. 将控制 Yield 到下一个 middleware
   3. 创建另外 date 记录响应时间
   4. 将控制 Yield 到下一个 middleware
   5. 立刻 Yield 控制, 因为 `contentLength` 只对 response 起作用
   6. 将 upstream Yield 到 Koa 的 空middleware.
   7. 如果请求路径不是 "/", 则跳过设置 body.
   8. 设置响应为 "Hello World"
   9. 如果有 body 则设置 `Content-Length`
   10. 设置头部字段
   11. 输出log
   12. 发送响应前设置 `X-Response-Time` 头字段
   13. 转会 Koa, Koa负责发送 response


注意最后的中间件 (step __6__) yields, 看起来没有转给任何东西, 但实际上他转给了 Koa 的空 generator. 这是为了保证所有
的中间件遵循相同的 API, 可以在其他中间件前边或后边使用. 如果你删掉最深 "downstream" 中间件的 `yield next;` 所有的功能
都还 OK, 但是不在遵循这个行为.

 例如如下代码也不会出错:

```js
app.use(function *response(){
  if ('/' != this.url) return;
  this.body = 'Hello World';
});
```

接下来是中间件开发最佳实践

## 中间件最佳实践

  这个环节介绍了中间件开发最佳实践相关内容: 可接受的选项, 给中间件命名有利于调试, 及其他.

### 中间件选项

  在开发中间件时遵循惯例是非常重要的: 使用接受参数的方法 wrapping 中间件, 这样用户可以扩展功能.
  即使你的中间件不接受选项, 保持所有事情一致也是最好的选择.

  如下是一个 `logger` 中间件, 接受 `format` 字符串, 用于自定义格式, 最后返回中间件.

```js
function logger(format){
  format = format || ':method ":url"';

  return function *(next){
    var str = format
      .replace(':method', this.method)
      .replace(':url', this.url);

    console.log(str);

    yield next;
  }
}

app.use(logger());
app.use(logger(':method :url'));
```

### 给中间件命名

  中间件命名不是强制的, 但如果中间件有名字, 在调试时会非常有帮助.

```js
function logger(format){
  return function *logger(next){

  }
}
```

### 将多个中间件组合为一个

  有时候你需要将多个中间件组合成一个, 从而方便重用或 exporting. 这时你可以用 `.call(this, next)` 将他们连起来, 然后将 yield 这个 chain 的方法返回.

```js
function *random(next){
  if ('/random' == this.path) {
    this.body = Math.floor(Math.random()*10);
  } else {
    yield next;
  }
};

function *backwords(next) {
  if ('/backwords' == this.path) {
    this.body = 'sdrowkcab';
  } else {
    yield next;
  }
}

function *pi(next){
  if ('/pi' == this.path) {
    this.body = String(Math.PI);
  } else {
    yield next;
  }
}

function *all(next) {
  yield random.call(this, backwords.call(this, pi.call(this, next)));
}

app.use(all);
```

  Koa 内部 使用 koa-compose 创建和调度中间件栈. [koa-compose](https://github.com/koajs/compose) 内部就是这样实现的.


### 响应中间件

  如果中间件用于响应请求, 需要跳过 downstream 的中间件可以直接省略 `yield next`. 通常路由中间件就是这样的, 而且在所有中间件里都可以省略.
  例如下面的例子会响应 "two", 但是三个都被执行了, 所以在 downstream "three" 中间件里就有可能修改响应结果.

```js
app.use(function *(next){
  console.log('>> one');
  yield next;
  console.log('<< one');
});

app.use(function *(next){
  console.log('>> two');
  this.body = 'two';
  yield next;
  console.log('<< two');
});

app.use(function *(next){
  console.log('>> three');
  yield next;
  console.log('<< three');
});
```

  The following configuration omits `yield next` in the second middleware, and will still respond
  with "two", however the third (and any other downstream middleware) will be ignored:
  在下面的例子中第二个中间件省略了 `yield next`, 最终响应结果还是 "two", 但是第三个(以后后面所有的 downstream 中间件)中间件被忽略了.

```js
app.use(function *(next){
  console.log('>> one');
  yield next;
  console.log('<< one');
});

app.use(function *(next){
  console.log('>> two');
  this.body = 'two';
  console.log('<< two');
});

app.use(function *(next){
  console.log('>> three');
  yield next;
  console.log('<< three');
});
```

  当最深的中间件执行 `yield next;`, 它实际上是 yield 的空方法, 这样可以保证 stack 中所有地方的中间件可以正常 compose.

## 异步操作

  [Co](https://github.com/visionmedia/co) 构成了 Koa generator 委托的基石. 让我们可以写非阻塞的顺序代码.
  例如如下代码. 读取 `./docs` 中的所有文件名, 并读取所有 markdown 的内容, 连接后赋给 body, 这所有的异步操作都是使用
  顺序代码实现的.


```js
var fs = require('co-fs');

app.use(function *(){
  var paths = yield fs.readdir('docs');

  var files = yield paths.map(function(path){
    return fs.readFile('docs/' + path, 'utf8');
  });

  this.type = 'markdown';
  this.body = files.join('');
});
```

## 调试 Koa

Koa 和许多相关的库都支持 __DEBUG__ 环境变量. 这是通过 [debug](https://github.com/visionmedia/debug) 实现的, debug 提供简单的条件 logging.

  例如, 如果想查看所有 koa 调试信息, 设置环境变量为 `DEBUG=koa*`, 这样在程序启动的时候, 可以看到所有使用的中间件列表.

```
$ DEBUG=koa* node --harmony examples/simple
  koa:application use responseTime +0ms
  koa:application use logger +4ms
  koa:application use contentLength +0ms
  koa:application use notfound +0ms
  koa:application use response +0ms
  koa:application listen +0ms
```

  虽然 JavaScript 不允许动态定义方法名, 但是你可以将中间件的名字设置为 `._name`.
  这在你无法修改中间件名字时非常有用如:

```js
var path = require('path');
var static = require('koa-static');

var publicFiles = static(path.join(__dirname, 'public'));
publicFiles._name = 'static /public';

app.use(publicFiles);
```

  现在, 在调试模式你不仅可以看到 "static", 还能:

```
  koa:application use static /public +0ms
```

