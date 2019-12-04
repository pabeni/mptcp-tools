CFLAGS=-Wall -fPIC

use_mptcp.so: wrapper.o
	gcc -shared -o $@ $^

clean:
	rm -f *.o *.so
