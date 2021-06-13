################################################################
# Code desctiption: This code provides basic signal analysis on
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

def digitalEnvelopeDetector(inputSampleTime, fileInputWithDir):
    print('Nothing')