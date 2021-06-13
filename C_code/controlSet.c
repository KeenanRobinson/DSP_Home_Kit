/***
Code description
Use this to set up control registers before
EPP is used.

Created by: Keenan Robinson
Supervisor: Dr Simon Winberg
*/
#include<stdio.h>
#include<unistd.h> //For the delay() function
#include "EPP_driver.h"

void print_error_msg(char* errmsg);

int main(int argc, char **argv) {
	if(argc != 1) print_error_msg("Incorrect number of args");
	if(initialise_port() < 0) //If unable to open the parallel port:
		print_error_msg("Unable to access the parallel port");
	first_setup();
	printf("Control set to xxxx0100");
	init_cntlPort(); //Reset = low. DataStrobe, Address

	//Finish
	return 0;
}

void print_error_msg(char *errmsg) {
	if(errmsg) {
		fprintf(stderr, "ERROR: %s\n", errmsg);
	}
	fprintf(stderr, "Syntax: sudo ./controlSet");

}
