/***
Code description:
This file contains all the necessary functions
required for executing the EPP_driver.c file. This
includes any IO port setup, clean-up, write and
read functionality.

Created by: Keenan Robinson
Supervised by: Dr Simon Winberg
Organisation: University of Cape Town
Date created: 05/05/2021

Reference documents:
http://as6edriver.sourceforge.net/Parallel-Port-Programming-HOWTO/modeselect.htm
https://www.csee.umbc.edu/courses/undergraduate/CMSC211/fall01/burt/lectures/CntlHardware/printers.html
*/

#include <stdio.h>
#include <stdlib.h>
#include <sys/io.h>
#include <time.h>
#include <unistd.h>

#include "EPP_driver.h"

/*
	dataRead_byte: perform a data read cycle, get data from peripheral FPGA
*/
int initialise_port() {
	int port_permission = ioperm(BASE, 5, 1);
	if(port_permission < 0) return 1; //Error; unable to provide IO access
	else printf("Port permission: %d\n", port_permission);

	int additionalPort_perm = ioperm(0x80, 1, 1);
	if(additionalPort_perm <0 ) return 1;
	else printf("0x80 Port permission: %d\n", additionalPort_perm);

	unsigned char EPP_ECR = 0x80; //Configure Extended Control Register (ECR) for EPP mode
	int ecr_perm = ioperm(BASE+0x402,1,1);
	if(ecr_perm <0) {
		return 1;
		printf("Error writing to the ECR control register");
	}
	unsigned char old_ECR = inb_p(BASE + 0x402); //ECR location
	unsigned char low_bits= old_ECR & 0x1f; //Save the lowest 5 bits
	unsigned char new_ECR = EPP_ECR | low_bits;
	outb_p(new_ECR, BASE + 0x402); //Set the port to EPP mode

	//Successful execution
	return 0;
}

int close_port() {
	//Port clean-up
	
	//Relinquish
	int port_permission = ioperm(BASE, 5, 0);
	if(port_permission < 0) return 1; //Error; unable to close IO access

	return 0;
}

/*******************************************************
first_set() - performs initial status port setting.
Note, this WILL reset the default channel assigned on
the FPGA. Run this only once on start up, otherwise use
init_cntlPort()
********************************************************/
void first_setup() {
	unsigned char ctl;
	//Set the control lines to the default xxxx0100
	ctl = inb(CONTROLPORT);
	ctl = (ctl & 0xF0) | 0x4;
	outb(ctl, CONTROLPORT);
}

/*******************************************************
init_cntlPort() - performs the same as the first_setup()
but without resetting the channel being read from.
Use this before every set of transactions, only once.
********************************************************/
void init_cntlPort() { 
	unsigned char ctl;
	//Set the control lines to the default xxxx0000, reset active low
	ctl = inb(CONTROLPORT);
	ctl = (ctl & 0xF0);
	outb(ctl, CONTROLPORT);
}

//Test setup => set pin 1 high/low for testing if the parallel port responds to commands
int testControlPin(unsigned char reg, unsigned char onOff) {
	unsigned char ctl;
	ctl = inb_p(CONTROLPORT);
	if(onOff) { //if it is ON
		ctl = (ctl & 0xF0) | (reg & 0xF); //Set the pin high depending on reg
		// while leaving top 4 MSBs the same.
	}
	else {
		ctl = ctl & ~(reg & 0xF); //set the pin low depending on reg bitmask
	}
	outb_p(ctl, CONTROLPORT); //set the value on the control port to change output
	return 0;
}
/*******************************************************
read_statusPort() - This reads back the status pins. This
is mainly for debugging and circuit testing.
********************************************************/
int read_statusPort(unsigned char *status) {
	//Assuming the port is already initialised.
	unsigned char sta;
	sta = inb_p(STATUSPORT);//Read the status port
	*status = (int)sta; //Convert the value to an integer, removing any leading 1's
	*status = *status & 255;	
	return 0;
}

/*******************************************************
set_dataPort() - This is used to set the value of the
data port. The value must be between 0 and 255
********************************************************/
int set_dataPort(int data) {
	if((data > 255) || (data < 0)) {
		printf("Data value is not within range.");
		return 1;
	}
	outb(data, BASE);
	return 0;
}

/***********	EPP read/write commands	************

/*******************************************************
set_dataPort(int addr, int *data) - This function tried 
to use the EPP data and address port to perform much faster
EPP transfers. This did not work due to the EPP timeout 
being too fast for the signal to be transferred.  
********************************************************/
int dataRead_byte(int addr, int *data) {
	//initialise the port
	if(initialise_port()< 0) return 1; //reset inactive HIGH
	first_setup(); //sets up the control ports

	//Clear EPP timeout
	unsigned char status;
	if ((inb(STATUSPORT) & 0x01)) { //If EPP time out has been set:
		status = inb(STATUSPORT);
		//Ensures any type of status port timeout is cleared, for most types of EPP ports
	  	outb(status | 0x01, STATUSPORT); 
	  	//outb(status & 0xFE, STATUSPORT); // Reset the EPP timeout
	}

	//Begin the data read process:
	unsigned char dataIn;
	//*data = 0; //Just for debugging
	//outb(addr, EPP_ADDRESS_PORT); 	//Select the channel, perform address write cycle
	dataIn = inb(EPP_DATA_PORT);	//Perform data read cycle
	printf("Read data: %d\n", (int)dataIn);

	//close the port
	//if(close_port() < 0) return 1; //End with error
	
	//Successful end execution
	return 0;
}

int read_port() {

  	int c;
	int BUSYLOOPCOUNT = 17000;
  	unsigned char readval, control;
	unsigned int usecs=10;
		

	clock_t t;
    	t = clock();
	//for (c=0;c<BUSYLOOPCOUNT;c++);;
	usleep(usecs);
	t = clock() - t;
	double time_taken = ((double)t)/CLOCKS_PER_SEC; // in seconds
	printf("Time taken(busyloop): %f\n", time_taken);

  	// put port in bidir, non-reset, read mode
    	t = clock();
  	control = 0x24; // 0010 0100 -> xxxx 1111
  	outb((unsigned char)control, BASE+2);
  	//for (c=0;c<BUSYLOOPCOUNT;c++);;
	usleep(usecs);

  	// pull strobe low
	control = 0x26; // 0010 0110 -> xxxx 1101
  	outb((unsigned char)control, BASE+2);
  	//for (c=0;c<BUSYLOOPCOUNT;c++);;
	usleep(usecs);

  	// At this point, we should wait until Wait is asserted, but this can
  	// be ignored because the device is fast

  	// read data
  	readval = inb(BASE);
  	printf("got this: %x\n",(int)readval);

  	// pull strobe high again
  	control = 0x24; // 0010 0100 -> xxxx 1111
  	outb((unsigned char)control, BASE+2);
  	//for (c=0;c<BUSYLOOPCOUNT;c++);;
	usleep(usecs);

	time_taken = ((double)t)/CLOCKS_PER_SEC; // in seconds
	printf("Time taken(dataRead): %f\n", time_taken);

  	// Go back into reset state
  	//set_reset();
  	for (c=0;c<BUSYLOOPCOUNT;c++);;

  	return 0;

}

/*******************************************************
dataRead_multiple(unsigned int no_of_16_bit_samples) - 
This is used to read the data buffer channel for the enabled
channel using multiple data read cycles. Returns the array 
of 8-bit values. Note, this is written in 'slow mode' of 
operation, as it takes multiple lines of code to execute 
the handshake EPP protocol.
********************************************************/
//int * dataRead_multiple
int dataRead_multiple(unsigned int no_of_16_bit_samples) {
	int readValues [no_of_16_bit_samples*2]; 
	//Need an additional read, as only one byte is transferred at a time

  	unsigned char readval, control;
	unsigned int usecs=0;
	
	clock_t t;
	t = clock(); //Used for measuring performance
	for(int i = 0;  i<no_of_16_bit_samples*2; i++) {	
  		// put port in bidir, non-reset, read mode
  		control = 0x24; // REG: 0010 0100 -> LINE: xxxx 1111
  		outb((unsigned char)control, CONTROLPORT);
		usleep(usecs);

  		// pull strobe low
		control = 0x26; // REG: 0010 0110 -> LINE: xxxx 1101
  		outb((unsigned char)control, CONTROLPORT);
		usleep(usecs);

  		//Here the PC should check for the wait signal, but since
  		//FPGA is so fast it is not required.

  		// Read data pins
  		readval = inb(BASE);
  		printf("Value read: %x\n", (int)readval);
		readValues[i] = readval; //Store the result in an array

  		// pull strobe high again
  		control = 0x24; // REG: 0010 0100 -> LINE: xxxx 1111
  		outb((unsigned char)control, CONTROLPORT);
  		//for (c=0;c<BUSYLOOPCOUNT;c++);;
		usleep(usecs);
	}
	t = clock() - t;
	double time_taken = ((double)t)/CLOCKS_PER_SEC; // Measured in seconds
	printf("Time taken(dataRead_multiple): %f\n", time_taken);

  	//return readValues; //return the pointer to this array
	return 0;
}
/*******************************************************
addrWrite(int addr) - This performs an address write
for EPP. 
********************************************************/

int addrWrite(unsigned char value) {
	unsigned char control;
	unsigned int usecs=12; 
	
	//Keep reset line=1, nWrite=0, write mode
	control = 0x0d; // REG: 0000 1101 -> LINE: xxxx 0110
	outb((unsigned char)control, CONTROLPORT);

	//Put address on data pins
	outb((unsigned char)value, BASE);
	usleep(usecs); //DELAY
	
	//Wait until nWait is asserted (=0 REG side)
	while((inb(STATUSPORT)&0x80) == 0x80) {
		continue;
	}

	//Pull nAddrStrobe high
	control = 0x05; // 0000 0101 -> xxxx 1110
	outb((unsigned char)control, CONTROLPORT);

	return 0;
}

int addrRead(unsigned char value) {
	unsigned char control;
	unsigned int usecs=12; 
	
	//Keep reset line=1, nWrite=1 (read mode)
	control = 0x2c; // REG: 0010 1100 -> LINE: xxxx 0111
	outb((unsigned char)control, CONTROLPORT);

	//Put address on data pins
	outb((unsigned char)value, BASE);
	usleep(usecs); //DELAY
	
	//Wait until nWait is asserted (=0 REG side)
	while((inb(STATUSPORT)&0x80) == 0x80) {
		continue;
	}

	//Pull nAddrStrobe high
	control = 0x24; // 0010 0100 -> xxxx 1111
	outb((unsigned char)control, CONTROLPORT);

	return 0;
}

void resetChannel(int nReset) {
  	char control;
	if(nReset==0) {
  		// Pull nReset line low, others high
  		control = 0x00; // REG: 0000 0000 -> LINE: xxxx 1011
		outb((unsigned char)control, BASE+2);
	}
	else {
		// Pull nReset line high, others high
  		control = 0x04; // 0000 0100 -> xxxx 1111
		outb((unsigned char)control, BASE+2);
	}
}
