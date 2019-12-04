#include <sys/syscall.h>

#include <netinet/in.h>
#include <linux/net.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

int socket(int family, int type, int protocol)
{
	if (protocol == IPPROTO_TCP) {
		if (getenv("USE_MPTCP_DEBUG"))
			fprintf(stderr, "use_mptcp: changing socket proto from %d to %d\n",
				protocol, protocol + 256);
		protocol += 256;
	}

	return syscall(__NR_socket, family, type, protocol);
}
