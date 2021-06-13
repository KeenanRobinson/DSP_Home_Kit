all: controlSet EPP_dataRead_byte EPP_readChannel EPP_setup EPP_stop readStatusPort testControlPin testDataPins

EPP_functions.o: EPP_functions.c EPP_driver.h
	gcc -Wall -O -c EPP_functions.c

controlSet.o: controlSet.c EPP_driver.h
	gcc -Wall -c controlSet.c

controlSet: controlSet.o EPP_functions.o
	gcc -Wall controlSet.o EPP_functions.o -o controlSet

EPP_dataRead_byte.o: EPP_dataRead_byte.c EPP_driver.h
	gcc -Wall -c EPP_dataRead_byte.c

EPP_dataRead_byte: EPP_dataRead_byte.o EPP_functions.o
	gcc -Wall EPP_dataRead_byte.o EPP_functions.o -o EPP_dataRead_byte

EPP_setup.o: EPP_setup.c EPP_driver.h
	gcc -Wall -c EPP_setup.c

EPP_setup: EPP_setup.o EPP_functions.o
	gcc -Wall EPP_setup.o EPP_functions.o -o EPP_setup

EPP_stop.o: EPP_stop.c EPP_driver.h
	gcc -Wall -c EPP_stop.c

EPP_stop: EPP_stop.o EPP_functions.o
	gcc -Wall EPP_stop.o EPP_functions.o -o EPP_stop

readStatusPort.o: readStatusPort.c EPP_driver.h
	gcc -Wall -c readStatusPort.c

readStatusPort: readStatusPort.o EPP_functions.o
	gcc -Wall readStatusPort.o EPP_functions.o -o readStatusPort

testControlPin.o: testControlPin.c EPP_driver.h
	gcc -Wall -c testControlPin.c

testControlPin: testControlPin.o EPP_functions.o
	gcc -Wall testControlPin.o EPP_functions.o -o testControlPin

testDataPins.o: testDataPins.c EPP_driver.h
	gcc -Wall -c testDataPins.c

testDataPins: testDataPins.o EPP_functions.o
	gcc -Wall testDataPins.o EPP_functions.o -o testDataPins

EPP_readChannel.o: EPP_readChannel.c EPP_driver.h
	gcc -Wall -c EPP_readChannel.c

EPP_readChannel: EPP_readChannel.o EPP_functions.o
	gcc -Wall EPP_readChannel.o EPP_functions.o -o EPP_readChannel

#testSlowMode.o: testSlowMode.c EPP_driver.h
#	gcc -Wall -c testSlowMode.c

#testSlowMode: testSlowMode.o EPP_functions.o
#	gcc -Wall testSlowMode.o EPP_functions.o -o testSlowMode

clean:
	rm -f *.o *~ controlSet EPP_dataRead_byte EPP_readChannel EPP_setup EPP_stop readStatusPort testControlPin testDataPins *.core


