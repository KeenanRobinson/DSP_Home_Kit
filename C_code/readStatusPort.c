/***
Code description:
This is a slow mode detection of the status ports
for the EPP. This is mainly used for testing circuitry.

Created by: Keenan Robinson
Supervised by: Dr Simon Winberg
Organisation: University of Cape Town
Date created: 05/05/2021
*/

#include <stdio.h>
#include <stdlib.h>
#include <sys/io.h>

#include "EPP_driver.h"

void print_error_msg(char* errmsg);

//No arguments required
int main(int argc, char **argv) {
	unsigned char status; 
	if(argc != 1) print_error_msg("Incorrect number of args");
	if(initialise_port() < 0) //If unable to open the parallel port:
		print_error_msg("Unable to access the parallel port");
	if(read_statusPort(&status) < 0) print_error_msg("Unable to change pin value");
	printf("Status port value: %d\n", status);
	//Finish
	return 0;
}

void print_error_msg(char *errmsg) {
	if(errmsg) {
		fprintf(stderr, "ERROR: %s\n", errmsg);
	}
	fprintf(stderr, "Syntax: readStatusPort");
}
