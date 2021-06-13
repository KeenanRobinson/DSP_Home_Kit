################################################################
# Code desctiption: This code is responsible for establishing the
# control necessary over the parallel port interface. The individual
# pins can be written to and controlled using the custom pyparallel
# library adjusted and provided by Lewis Loflin
#
#
# Created by: Keenan Robinson
# Supervisor: Dr Simon Winberg
# Date created: 26/05/2021

# Installation guide:
# https://www.bristolwatch.com/pport/index.htm

# Pins:     | SPP Label     |   EPP Label       | Direction (From PC):  
#   1       | nStrobe       | nWrite            | OUT
#   2       | Data0         | Data0             | bidirectional
#   3       | Data1         | Data1             | bidirectional
#   4       | Data2         | Data2             | bidirectional
#   5       | Data3         | Data3             | bidirectional
#   6       | Data4         | Data4             | bidirectional
#   7       | Data5         | Data5             | bidirectional
#   8       | Data6         | Data6             | bidirectional
#   9       | Data7         | Data7             | bidirectional
#   10      | nACK          | nInterrupt        | IN
#   11      | BUSY          | Wait              | IN
#   12      | Print Error   | <User defined>    | IN
#   13      | Select        | <User defined>    | IN
#   14      | nAUTO FEED    | nData Strobe      | OUT
#   15      | nError        | <User defined>    | IN
#   16      | nINIT         | nRESET            | OUT
#   17      | nSELECT IN    | nAddrStrobe       | IN 
#   18-25   | GND           |                   | IN

#NOTES: 
#   => nError = FPGA_ACK_INPUT, which indicates when the FPGA has identified it must be in input mode
#   => Select = FPGA_DONE, which indicates when the FPGA channel has no more data to be read

#Control commands (extracted from bristolwatch):
#################################################################
## Control pins:
# setDataStrobe(level)   - Set the "data strobe" line to the given state. Pin 1
# setAutoFeed(level)     - Set "auto feed" line to given state. Pin 14
# setInitOut(level)      - Set "initialize" line to given state. Pin (16) reset
# setSelect(level)       - Sets the state of the SelectIn output (pin 17)

# strobe()   - Returns the state of the nStrobe output (pin 1)
# autoFd()   - Returns the state of the nAutoFd output (pin 14)
# init()     - Returns the state of the nInit output (pin 16)
# selectIn() - Returns the state of the nSelectIn output (pin 17)
#################################################################
## Status pins:
# getInError()       - Returns the level on the nFault pin (15)
# getInSelected()    - Read level of "select" line. pin (13)
# getInPaperOut()    - Read level of "paper out" line. Pin (12)
# getInBusy()        - Returns the level on the Busy pin (11)
# getInAcknowledge() - Read level of "Acknowledge" line. Pin (10)
#################################################################
## Data port pins:
# setData(value)    - Apply the given byte to the data pins of the parallel port.
# data()            - Returns value of the data bus line drivers (pins 2-9)
# setDataDir(level) - 1 Activates or 0 deactivates the data bus line drivers (pins 2-9)
# dataDir()         - Returns true if the data bus line drivers are on (pins 2-9)"""

import parallel
import fpgaFileHandler
from datetime import datetime
p = parallel.Parallel() #Open LPT1, the port location for the onboard parallel port
defaultDirectory = 'D:/Downloads/Documents/University/Year_5/DSP@Home Kit/Python_code/fpga_data'

def initialiseParallelPort(): # Execute this once the FPGA has been setup and bitstream
    # has been uploaded.
    #Method             #Pin no.    #EPP line       #State       
    p.setDataStrobe(1)    # Pin 1,    nWrite = 1,     INACTIVE
    p.setDataDir(0)       # Pin 2-9,  data=INPUT,     INACTIVE
    p.setAutoFeed(1)      # Pin 14,   nDataStrobe=1,  INACTIVE 
    p.setInitOut(1)       # Pin 16,   nReset=1,       INACTIVE
    p.setSelect(1)        # Pin 17,   nAddrStrobe=1,  INACTIVE 


#def readPort(): #Single read operation from the FPGA or peripheral

#def writePort(): #Single write to the FPGA or peripheral

#def readData(inputAddr):     #Read all data from the FPGA or peripheral
 #   selectAddress(inputAddr) #First configure the 

#def writeInstruction(inputData):     #Read all data from the FPGA or peripheral

def addressWrite(inputAddr):
    # Command to select a specific channel to read from.

    # 1. Convert data pins to OUTPUT mode, delay to ensure that there is
    #    sufficient time for the FPGA to change mode.
    p.setDataStrobe(0)          # Pin 1,    write=0,            ACTIVE  
    while p.getInError() < 1:   # Pin 15, FPGA_ACK_IN
        pass #Do nothing while the program waits for the FPGA to respond to data direction change
    #Begin sending the data once the FPGA responds

    # 2. Send the address
    p.setDataDir(1)         # Pin 2-9,  data=OUTPUT,        ACTIVE
    p.setData(inputAddr)    # Pin 2-9,  data=inputAddr,     ACTIVE
    p.setSelect(0)          # Pin 17,   nAddrStrobe=0,      ACTIVE
    #Wait for the FPGA to respond
    while p.getInBusy() < 1:    # Pin11,    Wait
        pass #Do nothing while the program waits for the FPGA to respond that it has received the data
    #Once it has read that the FPGA has received and Wait has gone high, deassert AddrStrobe
    # 3. Reconfigure data pins back to input mode
    p.setData(0)
    p.setDataDir(0)         #Return to input mode for pin safety
    p.setDataStrobe(1)      # Pin 1,    write=1,            INACTIVE 
    p.setSelect(1)          # Pin 17,   nAddrStrobe=1,      INACTIVE

def dataReadAll(inputAddr): #Reads the entire bank/channel data, until the FPGA indicates that all data has been read
    allData = []
    # 1. Convert data pins to INPUT mode, delay to ensure that there is
    #    sufficient time for the FPGA to change mode.
    p.setDataDir(0)         # Pin2-9,   data=INPUT,         INACTIVE
    p.setData(0)            # Set data drivers to 0
    p.setDataStrobe(1)      # Pin 1,    write=1,            INACTIVE  
    
    #Begin reading the data process
    while p.getInSelected() < 1:    #while there is still data to be read
        p.setAutoFeed(0)        # Pin 14,   nDataStrobe=0,        ACTIVE 
        while p.getInBusy() < 1:    # Pin11,    Wait
            pass #Do nothing while the program waits for the FPGA to respond that it has acknowledged the read request
                    # and data is available
        dataByte = p.data()                 #Read the data lines
        allData.append(dataByte)            #Append it to a list
        p.setAutoFeed(1)        # Pin 14,   nDataStrobe=1,        INACTIVE
        while p.getInBusy() != 0:    # Pin11,    Wait
            pass #Do nothing while the program waits for the FPGA to return to not waiting, ready for the next transaction
    
    #Once the program has finished, read the values into a CSV file
    now = datetime.now()
    current_time = now.strftime("%H_%M_%S")
    fpgaFileHandler.writeCSV('D:/Downloads/Documents/University/Year_5/DSP@Home Kit/Python_code/fpga_data/singleColumnData/'
                +str(inputAddr)+'_'+str(current_time), allData)

def closePort(): #Execute this as cleanup after application execution
    #Method             #Pin no.    #EPP line       #State       
    p.setDataStrobe(0)    # Pin 1,    nWrite = 1,     INACTIVE
    p.setDataDir(0)       # Pin 2-9,  data=INPUT,     INACTIVE
    p.setAutoFeed(0)      # Pin 14,   nDataStrobe=1,  INACTIVE 
    p.setInitOut(0)       # Pin 16,   nReset=1,       INACTIVE
    p.setSelect(0)        # Pin 17,   nAddrStrobe=1,  INACTIVE 

#Debugging and testing: 
def testOutput():
    #Use this to test functionality and control over the parallel port
    p.setDataStrobe(1)      # Pin 1,    nWrite = 1,     INACTIVE
    p.setDataDir(1)         # Pin 2-9,  data=OUTPUT,    ACTIVE
    p.setAutoFeed(1)        # Pin 14,   nDataStrobe=1,  INACTIVE 
    p.setInitOut(1)         # Pin 16,   nReset=1,       INACTIVE
    p.setSelect(1)          # Pin 17,   nAddrStrobe=1,  INACTIVE

    p.writeD7(1)            # Pin 9,    data7=1,        ACTIVE

if __name__ == '__main__':
    testOutput()



    