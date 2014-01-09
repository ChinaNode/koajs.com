
DOCS = public/cn/index_cn.md \
  public/cn/context_cn.md \
  public/cn/request_cn.md \
  public/cn/response_cn.md

DOCS = public/readme.md

index.html: views/index.jade $(DOCS)
	@./node_modules/.bin/jade $< -o .

public/cn/index_cn.md:
	@./public/cn/index_cn.md \
	  | ./rewrite.js > $@

public/cn/context_cn.md:
	@./public/cn/context_cn.md \
	  | ./rewrite.js > $@

public/cn/request_cn.md:
	@./public/cn/request_cn.md \
	  | ./rewrite.js > $@
public/cn/response_cn.md:
	@./public/cn/response_cn.md \
	  | ./rewrite.js > $@

clean:
	rm -fr *.html

.PHONY: clean
