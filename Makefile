
DOCS = public/readme.md

index.html: views/index.jade $(DOCS)
	@./node_modules/.bin/jade $< -o .

public/readme.md:
	@./public/readme.md \
	  | ./rewrite.js > $@

clean:
	rm -fr *.html

.PHONY: clean
