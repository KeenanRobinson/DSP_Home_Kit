/***
Code Description:
The following file is used to test the EPP port
by reading a single byte from the peripheral
(Nexys A7 100T).

Created by: Keenan Robinson
Supervisor: Dr Simon Winberg
Company: University of Cape Town
Project: DSP@Home Kit, EEE4022F

*/
#include <stdio.h>
#include <stdlib.h>
#include "EPP_driver.h"

void print_error_msg(char* errmsg);
/***********************************************
* Main method - performs a single data read operation
***********************************************/
int main(int argc, char **argv) {
	int addr, data;
	initialise_port();
	first_setup();
	if(argc!=2) print_error_msg("Wrong number of arguments");
	if(sscanf(argv[1], "%i", &addr)!=1) print_error_msg("Invalid address");
	//if(dataRead_byte(addr, &data)) print_error_msg("Unable to read EPP port");
	//if(read_port()) print_error_msg("Unable to read EPP port");
	if(dataRead_multiple(addr)) print_error_msg("Unable to read EPP port");	
	
	//Finish
	return 0;
}

/***********************************************
* Error message method
***********************************************/
void print_error_msg(char* errmsg) {
	if(errmsg) {
		fprintf(stderr, "ERROR:%s\n", errmsg);
	}
	fprintf(stderr, "Syntax: EPP_dataRead_byte <channel address>\n");
	fprintf(stderr, "<channel address> should be between 0 and 255 only");
	exit(1);
}
