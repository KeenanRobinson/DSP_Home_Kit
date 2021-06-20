################################################################
# Code desctiption: Allows the Python interface to read data 
# acquired from the Nexys A7 through the parallel port, stored
# in Comma Separated Values (.csv) files. 
#
#
# Created by: Keenan Robinson
# Supervisor: Dr Simon Winberg
# Date created: 24/05/2021

# Requirements/Required libraries to include:
# pip
# tkinter 
# matplotlib 
# pyparallel

import csv
import random

# readCSV_test(filename, sampleSize)
# - just a test function to ensure data is completely read
#
# readCSV (filename, sampleSize)
# - Reads csv files and then returns a numpy array, combining lines 
#   of the csv file according to the dataWidth parameter. Since each
#   line of the csv is a bit, recompile it to form different data sizes
#   for example, if dataWidth = 8, first 8 lines of csv will be combined
#   and stored as the first entry in the numpy array.

defaultFileName = '/home/keenanrob/Documents/EEE4022F/channelCSVData/testCSV.csv'


def readCSV_test(filenameIn):
    with open(filenameIn, 'r') as csv_file:
        data = csv.reader(csv_file, delimiter = ';')
        for row in data:
            print(row)
    csv_file.close()
# Note: do not use excel to generate the CSV. It creates a ﻿ in the output.
# This is due to the way Excel format saves it in UTF-16 instead of UTF-8.

def csvGen(filenameWithDir, rows): #Made for simulation and testing
    with open(filenameWithDir, 'w', newline='') as csv_file:
        data_writer = csv.writer(csv_file, delimiter=';', quoting=csv.QUOTE_MINIMAL)

        for i in range (0,rows):
            data_writer.writerow([  random.randint(0,1),
                                    random.randint(0,1),
                                    random.randint(0,1),
                                    random.randint(0,1),
                                    random.randint(0,1),
                                    random.randint(0,1),
                                    random.randint(0,1),
                                    random.randint(0,1),
                                    0   ])
    csv_file.close()

def writeCSVRow(filenameWithDir, arrayIn):
    with open(filenameWithDir, 'a', newline='') as csv_file: #a = append mode
        data_writer = csv.writer(csv_file, delimiter=';', quoting=csv.QUOTE_MINIMAL)
        data_writer.writerow([  arrayIn[0], 
                                arrayIn[1],
                                arrayIn[2],
                                arrayIn[3],
                                arrayIn[4],
                                arrayIn[5],
                                arrayIn[6],
                                arrayIn[7],
                                arrayIn[8] ])
    csv_file.close()

def readCSV(filenameIn):
    with open(filenameIn, 'r') as csv_file:
        data = csv.reader(csv_file, delimiter = ';')
        for row in data:
            print(row)
    csv_file.close()

#def reformatCSV(filenameWithDir, datawidth):

#Converts samples in binary values.
def interpretAsDigitalCSV(filenameIn):
    dataList = []
    channelInfo=[]
    #Reads the values from a CSV file where dataWidth is one. Do not use this if the data is to be interpreted as a bus/multibit value.
    #Serialises the csv. Returns a list of the data, ignoring the last bit which indicates when a channel is finished
    with open(filenameIn, 'r', newline='') as csv_file:
        data = csv.reader(csv_file, delimiter = ',', quoting=csv.QUOTE_MINIMAL)
        entryCount = 0
        sampleTime = 0
        timeList = []
        dataList = []
        for entry in data:
            if entryCount == 0:
                channelInfo.append(int(entry[0])) #Number of samples
            elif entryCount == 1:
                channelInfo.append(float(entry[0])) #This is the sample rate
            elif entryCount == 2:
                channelInfo.append(int(entry[0])) #This is the channel
            else:
                binaryEntry = "{:0>16}".format(bin(int(entry[0]))[2:]) #Reformats to binary string
                for i in range (16):
                    dataList.append(binaryEntry[i])
                    timeList.append(sampleTime)
                    sampleTime = sampleTime+(1/(float(channelInfo[1]))) #Calculate the next time interval
            entryCount = entryCount+1
            #print(entryCount)

    csv_file.close()
    return [channelInfo, timeList, dataList]

def interpretAsAnalogCSV(filenameIn):
    dataList = []
    channelInfo=[]
    #Reads the values from a CSV file where dataWidth is one. Do not use this if the data is to be interpreted as a bus/multibit value.
    #Serialises the csv. Returns a list of the data, ignoring the last bit which indicates when a channel is finished
    with open(filenameIn, 'r', newline='') as csv_file:
        data = csv.reader(csv_file, delimiter = ',', quoting=csv.QUOTE_MINIMAL)
        entryCount = 0
        sampleTime = 0
        timeList = []
        dataList = []
        for entry in data:
            if entryCount == 0:
                channelInfo.append(int(entry[0])) #Number of samples
            elif entryCount == 1:
                channelInfo.append(float(entry[0])) #This is the sample rate
            elif entryCount == 2:
                channelInfo.append(int(entry[0])) #This is the channel
            else:
                binaryEntry = "{:0>16}".format(bin(int(entry[0]))[2:]) #Reformats to binary string
                dataList.append(binaryEntry)
                timeList.append(sampleTime)
                sampleTime = sampleTime+(1/(float(channelInfo[1]))) #Calculate the next time interval

            entryCount = entryCount+1
            #print(entryCount)

    csv_file.close()
    return [channelInfo, timeList, dataList]

def writeCSV_Decimal(filenameWithDir, inputList): #Here the data from the FPGA channel is converted to a single column
    with open(filenameWithDir, 'w', newline='') as csv_file:
        data_writer = csv.writer(csv_file, delimiter=';', quoting=csv.QUOTE_MINIMAL)

        for i in range (0, len(inputList)):
            dataEntryString = str(bin(inputList[i])[2:].zfill(8))
            data_writer.writerow([ 
                dataEntryString[0],
                dataEntryString[1],
                dataEntryString[2],
                dataEntryString[3],
                dataEntryString[4],
                dataEntryString[5],
                dataEntryString[6],
                dataEntryString[7]
            ])
        csv_file.close()

def bitErrorTest(fileDir): #Performs an bit-error test to evaluate accuracy.
    compareValue = 1 #initial starting value
    entryCount = 0
    numberOfErrors = 0
    testValues = []
    with open(fileDir, 'r', newline='') as csv_file:
        data = csv.reader(csv_file, delimiter=',', quoting=csv.QUOTE_MINIMAL)
        for entry in data:
            if entryCount > 2:
                testValues.append(int(entry[0]))
            entryCount = entryCount + 1
        csv_file.close()

    for i in range(len(testValues)): #For loop through the different data entries, comparing each 16-bit word
        if compareValue != testValues[i]:
            numberOfErrors = numberOfErrors+1
            print(testValues[i])
        compareValue = compareValue+1
        if(compareValue == 65536): #if the compare value has a bit width greater than 16, return to 0
            compareValue=0
    return numberOfErrors


if __name__ == '__main__':
    #array = interpretAsDigitalCSV(defaultFileName)
    #print(array)
    dir1 = '/home/keenanrob/Documents/EEE4022F/Result_resources/Bit_error_tests/1000000_samples.csv'
    print('Number of errors: ',bitErrorTest(dir1))