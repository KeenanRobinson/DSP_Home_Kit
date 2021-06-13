/***
Code description
Program used to constantly read from the parallel port,
writing to an array and dumping data into a CSV file.
The CSV file can then be used for plotting the data on
separate applications or for data analysis. 

Created by: Keenan Robinson
Supervisor: Dr Simon Winberg
*/
#include<stdio.h>
#include<unistd.h> //For the delay() function
#include <time.h>
#include <sys/io.h>

#include "EPP_driver.h"

void print_error_msg(char* errmsg);
void createCSV(int *valuesToConvert, int no_of_16_bit_samples);
void createCSV_test();
void handle_sigint();

const int buffer_size = 1000; //writes to CSV every 1000 16-bit samples

//*******USAGE: 
//sudo ./EPP_readChannel <File save directory> <Number of 16-bit samples> <frequency> <channelAddress> 
//************
//The last two arguments add as part of the header for the CSV file,
//where data can be extracted to reformat the samples as needed. 
int main(int argc, char **argv) {
	//int *channelValues;
	char fileDirectory[150];
	int no_of_16_bit_samples;
	double freq;
	unsigned char channelAddress;
	if(sscanf(argv[1], "%s", fileDirectory)!=1) {
		print_error_msg("Invalid directory");
		return 1;
	}
	if(sscanf(argv[2], "%d", &no_of_16_bit_samples)!=1) {
		print_error_msg("Invalid number for samples");
		return 1;
	}
	if(sscanf(argv[3], "%f", &freq)!=1) {
		print_error_msg("Invalid number for clock divider");
		return 1;
	}
	if(sscanf(argv[4], "%s", fileDirectory)!=1) {
		print_error_msg("Invalid directory");
		return 1;
	}
	if(sscanf(argv[5], "%d", &channelAddress)!=1) {
		print_error_msg("Invalid channel address");
		return 1;
	}
	if(initialise_port() < 0) { //If unable to open the parallel port:
		print_error_msg("Unable to access the parallel port");
		return 1;	
	}
	printf("Number of 16-bit samples:%d\n", no_of_16_bit_samples);
	printf("Directory: %s\n", fileDirectory);
	printf("Clock Divider: %d\n", clk_div);

	//First perform a channel select operation - from EPP_functions.c
	int result = addrWrite(channelAddress);
	if(result != 0) {
		print_error_msg("Unable to select channel");
		return 1;
	}
	 
	//copied code from dataRead_multiple() to perform the dataRead
	//functionality repeatedly. 
  	unsigned char control;
	unsigned short readValues[buffer_size];
	int sample_count = 0;
	int buffer_count = 0; // This counts the number of samples to store in array buffer before written to CSV.
	unsigned char combineValue = 0; //This indicates when two bytes need to be combined.
	unsigned short word_16_bit_buffer = 0;	//Stores the first byte
	unsigned int usecs=0;
	FILE *fpt;
	unsigned char SELECT = 0x10;
	
	clock_t t;
	t = clock(); //Used for measuring performance
	while(sample_count != no_of_16_bit_samples) {
		if((inb(STATUSPORT) & SELECT) != 0) {//Only read data when the channel has data to be read. SELECT = 1 if memory buffer on FPGA is not empty.
  			// put port in bidir, non-reset, read mode
  			control = 0x24; // REG: 0010 0100 -> LINE: xxxx 1111
  			outb((unsigned char)control, CONTROLPORT);
			usleep(usecs);

  			// pull nDataStrobe low
			control = 0x26; // REG: 0010 0110 -> LINE: xxxx 1101
  			outb((unsigned char)control, CONTROLPORT);
			usleep(usecs);

  			// Here the PC should check for the wait signal, but due to the 
			// host PC overhead it does not need to and polling would reduce
			// performance.

  			// Read data, convert to 16-bit length
			if(combineValue) {
				word_16_bit_buffer = (unsigned short)inb(BASE); 	//Store what is written on data pins
				combineValue = 1;		//Indicate next transaction will form the full 16-bit word 
				control = 0x24; // REG: 0010 0100 -> LINE: xxxx 1111
  				outb((unsigned char)control, CONTROLPORT);			
			}
			else {
				readValues[buffer_count] = (word_16_bit_buffer*256)+(unsigned short)inb(BASE); //Shifts present data and stores next byte
  				combineValue = 0;
				sampleCount++; 
				//End the transaction, setting strobe high again
				control = 0x24; // REG: 0010 0100 -> LINE: xxxx 1111
  				outb((unsigned char)control, CONTROLPORT);
				printf("Value read: %x\n", (int)readValues[buffer_count]);
				buffer_count++; //Increment buffer_count
				if(buffer_count >= buffer_size-1) {
					//Begin writeCSV transaction
					clock_t writeCSV_t;
					writeCSV_t = clock();
					fpt = fopen(fileDirectory, "a+");
					for(int i = 0; i < buffer_size; i++) {		//Write the values to the CSV. This takes ~200us.
						fprintf(fpt,"%d\n", readValues[i]);
					}
					fclose(fpt); //close the file
					buffer_count = 0; //reset the array buffer count
					double writeCSV_time_taken = ((double)writeCSV_t)/CLOCKS_PER_SEC; // Measured in seconds
					printf("Time taken to write buffer to the CSV: %f\n", writeCSV_time_taken);
				}		
			}
		}
		//Else if waiting, do nothing
	} //End while loop
	t = clock() - t;
	double time_taken = ((double)t)/CLOCKS_PER_SEC; // Measured in seconds
	printf("Total Time taken(dataRead): %f\n", time_taken);

	//Finish
	return 0;
}

void print_error_msg(char *errmsg) {
	if(errmsg) {
		fprintf(stderr, "ERROR: %s\n", errmsg);
	}
	fprintf(stderr, "Syntax: sudo ./EPP_readChannel <Number of samples> <Clock Divider> <Bit length> ");
}

void createCSV(int *valuesToConvert, int no_of_16_bit_samples) {
	FILE *fpt;
	fpt = fopen("/home/keenanrob/Documents/EEE4022F/channelCSVData/MyFile1.csv", "a+");
	int temp[8];
	for(int i = 0; i < (no_of_16_bit_samples*2); i++) {
		int value = *(valuesToConvert+i);
		for (int j=0; j < 8; j++) {		
			temp[j] = value%2;
			value = value/2;
		}
		fprintf(fpt,"%d,%d,%d,%d,%d,%d,%d,%d", temp[7],temp[6],temp[5],temp[4],temp[3],temp[2],temp[1],temp[0]);
	}
}

void createCSV_test() {	//Test function to see if csv file can be written
	FILE *fpt;
	clock_t t;
	t = clock();
	fpt = fopen("/home/keenanrob/Documents/EEE4022F/channelCSVData/MyFile1.csv", "a+");
	for(int i = 0; i < 1; i++) {
		fprintf(fpt,"%d\n", i);
		//fclose(fpt);
	}
	fclose(fpt);
	t = clock() - t;
	double time_taken = ((double)t)/CLOCKS_PER_SEC; // Measured in seconds
	printf("Time taken (createCSV_test()): %f\n", time_taken);
}

