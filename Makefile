out ?= ./build/out.pdf

.DEFAULT: build

.PHONY: build
build:
	mkdir -p $(dir $(out))
	typst compile --root . --input DIRTY_REV=$(DIRTY_REV) src/main.typ $(out)

.PHONY:
clean:
	rm -r ./build
