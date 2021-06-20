################################################################
# Code description: This file provides the user the ability to use
# the C files created to drive the parallel port. C programming
# offers significant speed up compared to software loop iterations
# in Python, which was important to ensure fastest communication between
# attached FPGA and the host PC
#
# Created by: Keenan Robinson
# Supervisor: Dr Simon Winberg
# Date created: 7/06/2021

# Requirements/Required libraries to include:
# pip
# tkinter
# matplotlib
# pyparallel
# os
import os

cCodeExecutableLocation = "sudo ./home/keenanrob/Documents/EEE4022F/C_code"

# This code launches the c code driver responsible for allowing the parallel port read driver
def readChannel(savefileDirectory, noOf16BitSamples, freq, channelAddr):
    home_dir = os.system("cd ~")
    print("Return to home directory with exit code %d" % home_dir)
    compileString = (f"{cCodeExecutableLocation}"
                     f"/EPP_readChannel"
                     f"{savefileDirectory} "
                     f"{noOf16BitSamples} "
                     f"{freq} "
                     f"{channelAddr}").format(savefileDirectory, noOf16BitSamples, freq, channelAddr)
    print(compileString)
    run_file = os.system(compileString)
    return run_file


# Function list => use these calls to run the C executables provided under
# the C_code directory. NOTE: root access is required to run these!
if __name__ == '__main__':
    output = readChannel(' /home/keenanrob/Documents/EEE4022F/channelCSVData/PythonExectest.csv', 500, 3000, 1)
    print(output)
