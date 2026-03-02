test:
	./newf -vf -xt sh 1.sh -TX text 1.py -t ./fun 1.pl

clean:
	rm ./newf

.PHONY: test clean
