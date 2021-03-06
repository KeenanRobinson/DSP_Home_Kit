################################################################
# Code description: This code provides basic signal analysis on
# the input data. This data comes from the FPGA and is stored in
# the appropriate format. This is where custom functions can be
# created to manipulate the data. 
#
#
# Created by: Keenan Robinson
# Supervisor: Dr Simon Winberg
# Date created: 26/05/2021
#
# Available functions:
# - digitalEnvelopeDetection()
#   Used to detect where the signal is high and where it is low, along with duration
# - fourierTransform()
#   Used to convert the input samples to a fourier representation
# - convertToWav()
#   Converts the csv to a .wav or audio file
#
import scipy
from scipy import signal
import numpy as np
import csv
import math
import fpgaFileHandler
import matplotlib.pyplot as plt
from scipy.fft import fft, fftfreq
plt.rcParams["font.family"] = "Times New Roman"

#Produces time intervals for when the signal is high and when it is low, useful for IR decoding
def digitalEnvelopeDetector(fileDir1):
    data = fpgaFileHandler.interpretAsDigitalCSV(fileDir1)
    dataStr = data[2] #Extracts the binary samples
    data = [int(entry) for entry in dataStr]  # convert to integer array
    print(len(data))
    duration = 0
    totalDuration = 0
    prevSample = 0
    for i in range(len(data)):
        if data[i]==1: #If the data has a value of one
            if prevSample==1:
                duration = duration+1
            else:
                print('0: ', duration,'us')
                totalDuration = totalDuration+duration
                duration = 1
                prevSample = 1
        else:
            if prevSample==0:
                duration = duration+1
            else:
                print('1: ', duration,'us')
                totalDuration = totalDuration + duration
                duration = 1
                prevSample = 0
    if(prevSample==0):
        print('0: ', duration, 'us')
    else:
        print('1: ', duration, 'us')
    totalDuration = totalDuration + duration
    print('Total duration: ', totalDuration, 'us')


def determineCorrelation(fileDir1, fileDir2):
    # fileDir1 is the CSV file for the first data set to compare
    # fileDir1 is the CSV file for the second data set to compare
    results = []
    firstChannel = fpgaFileHandler.interpretAsDigitalCSV(fileDir1)
    secondChannel = fpgaFileHandler.interpretAsDigitalCSV(fileDir2)
    data1Str = firstChannel[2]  # Extracts binary samples
    data2Str = secondChannel[2]  # Extracts binary samples

    # print(firstChannel[2])
    # print(secondChannel[2])

    data1 = [int(entry) for entry in data1Str]  # convert to integer array
    data2 = [int(newEntry) for newEntry in data2Str]  # convert to integer array
    data1 = np.array(data1)  # convert to numpy array
    data2 = np.array(data2)  # convert to numpy array

    # data3 = [1, 3, -2, 4]
    # data4 = [2, 3, -1, 3]
    # data3 = [1,2,-2,4,2,3,1,0] # Test data
    # data4 = [2,3,-2,3,2,4,1,-1] # Test data
    # data4 = [-2,0,4,0,1,1,0,-2] # test data

    # data3 = np.array(data3)
    # data4 = np.array(data4)

    corr = signal.correlate(data1, data2, mode='same')
    data0 = np.zeros((100000,), dtype=int)
    data0[0] = 1
    # print(data0)

    # print(data1*data2)
    # computedNCC = sum(data1*data0)/math.sqrt(sum(data1*data1)*sum(data0*data0))
    computedNCC = sum(data1 * data2) / math.sqrt(sum(data1 * data1) * sum(data2 * data2))
    print('Normalised correlation:', computedNCC)

    # computedNCC1 = sum(data3 * data4) / math.sqrt(sum(data3 * data3) * sum(data4 * data4))
    # print(computedNCC1)

    # fig, (ax_data1, ax_data2, ax_corr) = plt.subplots(3, 1, sharex=True)
    # ax_data1.plot(data1)
    # ax_data1.set_title('Data 1')
    # ax_data2.plot(data2)
    # ax_data2.set_title('Data 2')
    # ax_corr.plot(corr)

    # ax_corr.axhline(0.5, ls=':')
    # ax_corr.set_title('Cross-correlated of Data 1 and 2')
    # ax_data1.margins(0, 0.1)
    # fig.tight_layout()
    # plt.show()
    # print(data1)

def irComparisonGraphs(channelDir_36khz, channelDir_38khz, channelDir_40khz):
    channel_36khz = fpgaFileHandler.interpretAsDigitalCSV(channelDir_36khz)
    channel_38khz = fpgaFileHandler.interpretAsDigitalCSV(channelDir_38khz)
    channel_40khz = fpgaFileHandler.interpretAsDigitalCSV(channelDir_40khz)

    fig,(ax_36khz,ax_38khz,ax_40khz)=plt.subplots(3,1,sharex=False)
    #36kHz
    ax_36khz.plot(channel_36khz[1], channel_36khz[2])
    ax_36khz.set_title('36kHz Channel')
    ax_36khz.set_xlabel('Time (s)')
    ax_36khz.set_ylabel('Binary value')
    #38kHz
    ax_38khz.plot(channel_38khz[1], channel_38khz[2])
    ax_38khz.set_title('38kHz Channel')
    ax_38khz.set_xlabel('Time (s)')
    ax_38khz.set_ylabel('Binary value')
    #40kHz
    ax_40khz.plot(channel_40khz[1], channel_40khz[2])
    ax_40khz.set_title('40kHz Channel')
    ax_40khz.set_xlabel('Time (s)')
    ax_40khz.set_ylabel('Binary value')

    fig.tight_layout()
    plt.show()


def normCorrWithOscilloscope(oscilloscopeCSV, compareChDir):
    # First read the correct data format from the oscilloscope:
    #
    entryCount = 0
    oscData = []
    with open(oscilloscopeCSV, 'r', newline='') as csv_file:
        data = csv.reader(csv_file, delimiter=',', quoting=csv.QUOTE_MINIMAL)
        for entry in data:
            #print(entry)
            if (entryCount > 1) & (entryCount < 502):
                #print(entry[1])
                oscData.append(entry[1])
            entryCount = entryCount + 1
        csv_file.close()
    #print(oscData)
    oscData = [float(entry) for entry in oscData]
    oscData = np.array(oscData)
    #print(oscData)
    #print(len(oscData))

    firstChannel = fpgaFileHandler.interpretAsDigitalCSV(compareChDir)
    data1Str = firstChannel[2]  # Extracts binary samples
    data1 = [float(entry) for entry in data1Str]  # convert to float array
    reducedSamplesData = []
    dataCount = 199 #Acquire every 200th sample. Oscilloscope samples every 200us, while the data from the CSV
    # is sampled every 1us
    #Reduce the number of samples by reducing the sample rate, so that both signals have same number of samples
    for i in range(len(data1)):
        if dataCount==199:
            reducedSamplesData.append(data1[i])
            dataCount=0
        else:
            dataCount = dataCount+1
    #print(len(reducedSamplesData))
    reducedSamplesData = np.array(reducedSamplesData)*3.32

    computedNCC = sum(oscData * reducedSamplesData) / math.sqrt(
        sum(oscData * oscData) * sum(reducedSamplesData * reducedSamplesData))
    print('Normalised correlation:', computedNCC)

    fig, (ax_osc, ax_compareChannel) = plt.subplots(2, 1, sharex=False)
    ax_osc.plot(oscData)
    #ax_osc.set_title('Oscilloscope data')
    ax_osc.set_xlabel('Sample')
    ax_osc.set_ylabel('Voltage [V]')
    ax_compareChannel.plot(reducedSamplesData)
    ax_compareChannel.set_xlabel('Sample')
    ax_compareChannel.set_ylabel('Voltage [V]')
    #ax_compareChannel.set_title('38kHz Compare channel')
    # ax_corr.plot(corr)

    # ax_corr.axhline(0.5, ls=':')
    # ax_corr.set_title('Cross-correlated of Data 1 and 2')
    #ax_data1.margins(0, 0.1)
    fig.tight_layout()
    plt.show()

def fftData(channelDataDir):
    #Setup ideal sine wave form of same frequency with FFT
    sampleRate = 8000
    period = 1/8000
    t = 3.0 #100ms duration
    noOfSamples = sampleRate*t
    print(noOfSamples)
    frequency = 1000 #known frequency for testing
    omega = 2*np.pi*frequency
    t_sequence = np.arange(noOfSamples)*period
    print(t_sequence)
    y = 1.65*np.sin(omega*t_sequence)+1.65

    yf = fft(y)
    xf = fftfreq(int(noOfSamples), 1/int(sampleRate))

    #plt.plot(xf, np.abs(yf))
    plt.show()

    # Acquire channel data
    firstChannel = fpgaFileHandler.interpretAsAnalogCSV(channelDataDir)
    #Convert the ADC format to voltage level

    voltages = [float(entry)*(3.3/4096) for entry in firstChannel[2]]
    vf = fft(voltages)

    fig, (ax_ideal, ax_compareChannel) = plt.subplots(2, 1, sharex=True)
    #fig, ax_ideal = plt.subplots(1, 1, sharex=True)
    ax_ideal.plot(xf, np.abs(yf))
    ax_ideal.set_title('Ideal sine wave FFT')
    ax_ideal.set_xlabel('Frequency')
    ax_ideal.set_ylabel('FFT')

    ax_compareChannel.plot(xf, np.abs(vf))
    ax_compareChannel.set_title('Channel data FFT')
    ax_compareChannel.set_xlabel('Frequency')
    ax_compareChannel.set_ylabel('FFT')

    plt.show()


if __name__ == '__main__':
    # Test correlation between different signals:
    dir1 = '/home/keenanrob/Documents/EEE4022F/channelCSVData/ch1_ir_38khz_2m.csv'
    dir2 = '/home/keenanrob/Documents/EEE4022F/channelCSVData/ch3_ir_40khz_2m.csv'
    dir3 = '/home/keenanrob/Documents/EEE4022F/channelCSVData/ch2_ir_36khz_2m.csv'
    print('38kHz and 40kHz:')
    determineCorrelation(dir1, dir2)
    print('38kHz and 36kHz:')
    determineCorrelation(dir1, dir3)
    print('36kHz and 40kHz:')
    determineCorrelation(dir3, dir2)
    #Test correlation with oscilloscope:
    oscilloscopeDir = '/home/keenanrob/Documents/EEE4022F/Result_resources/final_ir.csv'
    print('Oscilloscope vs 38khz:')
    normCorrWithOscilloscope(oscilloscopeDir, '/home/keenanrob/Documents/EEE4022F/channelCSVData/ch1_ir_38khz_2m.csv')
    #Show the IR channels
    irComparisonGraphs(dir3, dir1, dir2)
    # Test the envelope detector:
    #digitalEnvelopeDetector(dir1)
    #fftData('/home/keenanrob/Documents/EEE4022F/channelCSVData/ch1_audio_8khz_3s.csv')
