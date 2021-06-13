/***
Code description:
This program initialises the parallel port as well as sets
up the EPP mode. Note that it will reset the FPGA due to
initialise_port() and thus should only be used once. 

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
	if(initialise_port() < 0) { //Set IO permissions
		print_error_msg("Unable to get permssions to access the parallel port");
		return 1;	
	}
	outb(0, BASE); //Writes low to all the data pins
	first_setup();   //initialise the control port with reset = 1
	//init_cntlPort(); //initialise the control port with reset = 0
	return 0;
}

void print_error_msg(char *errmsg) {
	if(errmsg) {
		fprintf(stderr, "ERROR: %s\n", errmsg);
	}
	fprintf(stderr, "Syntax: EPP_setup");
}
