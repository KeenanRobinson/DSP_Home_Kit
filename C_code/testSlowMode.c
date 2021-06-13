#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "EPP_driver.h"

void print_error(char* errmsg);

/*******************************************************************************
 * Main function
 ******************************************************************************/
int main(int argc, char **argv) {                    


  // Check input
  if (argc!=1)
    print_error("Wrong number of arguments");

  // Make sure we have permission to use the parallel port
  if (initialise_port() <0)
    print_error("Cannot open parallel port");

  // Read port and print data
	//read_port();
	dataRead_multiple();
  // Finished
  return 0;

}

/*******************************************************************************
 * Error routine
 * Prints an error message and syntax information
 * Parameters: option error message
 * Exits as a failure
 ******************************************************************************/
void print_error(char* errmsg) {

  if (errmsg) {
    fprintf(stderr,"ERROR: %s\n",errmsg);
  }
  fprintf(stderr,"Syntax: testSlowMode\n");
  exit(1);

}
