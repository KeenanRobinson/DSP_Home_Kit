#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/io.h>

#include "EPP_driver.h" //does not actually use it, but it should

#define base 0x378           /* printer port base address */
#define value 0            /* numeric value to send to printer port */

int main(int argc, char **argv)
{
	if (ioperm(base,1,1))
        fprintf(stderr, "Couldn't get the port at %x\n", base), exit(1);
	/*int dataPinValue = inb(base);
	printf("Data pins: %d\n", dataPinValue );*/
	outb(value, base);
	return 0;
}
