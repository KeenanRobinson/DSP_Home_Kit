#ifndef EPP_DRIVER_HEADER
#define EPP_DRIVER_HEADER
/***
Header file for the EPP_driver.c file.
*/
//Constants
#define BASE  0x378 //This is the memory location of the used parallel port.
#define STATUSPORT  (BASE+1) //Status port registers
#define CONTROLPORT  (BASE+2) //Control port registers
#define EPP_ADDRESS_PORT  (BASE+3) //Generates an interlocking address read/write
#define EPP_DATA_PORT (BASE+4)	//Generates an interlocking data read/write
//Function declarations

int initialise_port();
int close_port();
void first_setup();
void init_cntlPort();
int testControlPin(unsigned char reg, unsigned char onOff);
int read_statusPort(unsigned char *status);
int set_dataPort(int data);
int dataRead_byte(int addr, int *data);
int read_port();
//int * dataRead_multiple(unsigned int no_of_16_bit_samples);
int dataRead_multiple(unsigned int no_of_16_bit_samples);
int addrWrite(unsigned char value);
int addrRead(unsigned char value);

#endif
