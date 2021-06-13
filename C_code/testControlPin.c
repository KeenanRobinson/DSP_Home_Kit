/***
Code description
This program allows the control and testing of one control pin.
This is mainly to see if the C programs respond as required
by the IO setup, and if there is changing of the pin values.

Created by: Keenan Robinson
Supervisor: Dr Simon Winberg
*/
#include<stdio.h>
#include<unistd.h> //For the delay() function
#include "EPP_driver.h"

void print_error_msg(char* errmsg);

int main(int argc, char **argv) {
	int reg, onOff; //onOff: 1 = on, 0 = off
	if(argc != 3) print_error_msg("Incorrect number of args");
	if(sscanf(argv[1], "%i",&reg)!=1) print_error_msg("Invalid register");
	if(sscanf(argv[2], "%i",&onOff)!=1) print_error_msg("Invalid onOff value");
	if(initialise_port() < 0) //If unable to open the parallel port:
		print_error_msg("Unable to access the parallel port");
	if(testControlPin(reg, onOff) < 0) print_error_msg("Unable to change pin value");

	//Finish
	return 0;
}

void print_error_msg(char *errmsg) {
	if(errmsg) {
		fprintf(stderr, "ERROR: %s\n", errmsg);
	}
	fprintf(stderr, "Syntax: testPin 0x<register> 0x<onOff>");
	fprintf(stderr, "<register> Can only be between xxxx0000 - xxxx1111");
}
