/***
Code description:
This program closes the parallel port safely. This ensures
the data pins also return to low state.

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
	if(argc != 1) print_error_msg("Incorrect number of args");
	
	if(close_port() < 0) //initialise the control port with reset = 0
		print_error_msg("Unable to close the parallel port successfully.");
	return 0;
}

void print_error_msg(char *errmsg) {
	if(errmsg) {
		fprintf(stderr, "ERROR: %s\n", errmsg);
	}
	fprintf(stderr, "Syntax: EPP_stop");
}
