.PHONY: all cython ext doc clean test wheels

all: cython ext

cython:
	cython --version
	cython --cplus --fast-fail --annotate plyvel/_plyvel.pyx

ext: cython
	python setup.py build_ext --inplace --force

doc:
	python setup.py build_sphinx
	@echo
	@echo Generated documentation: "file://"$$(readlink -f doc/build/html/index.html)
	@echo

clean:
	python setup.py clean
	$(RM) plyvel/_plyvel.cpp plyvel/_plyvel*.so
	$(RM) -r testdb/
	$(RM) -r doc/build/
	$(RM) -r plyvel.egg-info/
	find . -name '*.py[co]' -delete
	find . -name __pycache__ -delete

test: ext
	py.test

wheels: cython
	# Note: this should run inside the docker container.
	for dir in /opt/python/*; do \
		$${dir}/bin/python setup.py build --force; \
		$${dir}/bin/python setup.py bdist_wheel; \
	done
	for wheel in dist/*.whl; do \
		auditwheel show $${wheel}; \
		auditwheel repair -w /dist/ $${wheel}; \
	done

sdist: cython
	# Note: this should run inside the docker container.
	python setup.py sdist --dist-dir /dist

release:
	docker build -t plyvel-build .
	docker run -i -t -v $(pwd)/dist/:/dist plyvel-build
