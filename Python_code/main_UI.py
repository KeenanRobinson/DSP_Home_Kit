################################################################
# Code description: Code for the Python control UI for the
# DSP@Home Kit. The interface allows users to send and receive 
# data to the FPGA using the parallel port.
#
# Created by: Keenan Robinson
# Supervisor: Dr Simon Winberg
# Date created: 17/05/2021

# Requirements/Required libraries to include:
# pip
# tkinter 
# matplotlib 
# pyparallel

from logging import FileHandler
from os import terminal_size
import tkinter as tk
from tkinter import ttk
from tkinter import *
from tkinter import font
import tkinter.scrolledtext as ScrolledText
import numpy as np
import tkinter.filedialog

# Other modules
import fpgaFileHandler

#Matplotlib
import matplotlib
matplotlib.use("TkAgg")
from matplotlib.backends.backend_tkagg import (FigureCanvasTkAgg, NavigationToolbar2Tk)
from matplotlib.figure import Figure
from matplotlib import style
import matplotlib.pyplot as plt
import math
import os


HEADING_FONT= ("Arial", 12, "underline", "bold")
NORMAL_FONT= ("Arial", 11)
NORMAL_FONT_BOLD= ("Arial", 11, "bold")
style.use("ggplot")

GREETING_MESSAGE= """Welcome to the DSP@Home Kit. To correctly use this interface, please follow the tutorial to understand how this interface operates."""

FOLLOW_UP_MESSAGE= """Please note the following:
\u2022 The Pmod pins provided are setup for the Nexys A7 100T. 
\u2022 Please ensure the FPGA is connected to the computer before bootup, as the parallel port is not hot-swappable and 
    connecting it later may cause damage to the pins. 
\u2022 The FPGA needs to be synthesised before it can start running. Please ensure that all the necessary channels are setup as intended.
    Use the button below labelled 'Preconfiguration settings' to determine parameters for setting up the FPGA. Follow the tutorial to 
    gain a better understanding of what is intended. 
"""

CONFIG_SETUP_MESSAGE = """The purpose of this is to produce the necessary parameter values for the Verilog configuration of a single channel. These parameters must
be copied into the module parameters, as it sets up necessary settings for that channel. Multiple channels can be created but memory usage needs to be considred.
The idea is to reconfigure memory modules present on the device, such as the block RAMs, according to the needs of the application. This provides information 
such as sample rate, possible duration (dependent on the number of enabled channels and sample rate, leading to memory availability), trigger types (trigger 
types can be buttons or rising/falling edge of a channel). """

SAMPLE_RATE_MESSAGE = """Insert the channel's sampling frequency. Note: the FPGA works on a 100MHZ clock and this determines the input frequency. The nearest frequency
determines the actual frequency that will be used by the channel. Adjust this to get a value more suitable value closer the value required."""

SAMPLES_MESSAGE = """This is the number of samples to be captured. This is used to determine amount of memory to be used."""

INPUT_DATA_WIDTH_MESSAGE = """This relates the width of the input data stream/bus. For digital signal paths, this is typically one. This input could be connected to a Pmod
port on the FPGA, or the output of another module (for example, an SPI module)."""

PARAMETER_MESSAGE = """The following output can be copied and pasted into the module definition responsible for starting and ending the recording, in the top module."""

CONFIG_MESSAGE = "For this section, the sampling channel must already be configured on the FPGA device. Here, the channel can be reconfigured such as the sample rate, " \
                 "resetting the channel(clearing memory and trigger), as well as to start streaming data or request data. When you request data, you need to supply the" \
                 "number of samples to be collected from the FPGA."
#Global declarations
class DSPHomeKit(tk.Tk): #Inherit tk.Tk
    def __init__(self, *args, **kwargs): #Method, initialise with class
        tk.Tk.__init__(self, *args, **kwargs) #Self is implied already. Initialise Tkinter
        #self.iconbitmap(self, default="clienticon.ico") #For creating an icon for the window
        #self.wm_title(self, "DSP@Home Kit Interface")
        tk.Tk.wm_title(self, "DSP@Home Kit Interface Client")

        self.geometry("1250x950") # width x height
        container = tk.Frame(self)      #Create a frame to embed the GUI
        container.grid(row=0, column = 0, sticky = 'N')
        container.grid_rowconfigure(0, weight=1)
        container.grid_columnconfigure(0, weight=1)

        self.frames = {} #Creates a dictionary for storing the different pages/frames
        #Frame selection/GUI Pages
        for myFrames in (
            StartPage,
            GraphPage,
            ChannelSetup):

            frame = myFrames(container, self)

            self.frames[myFrames] = frame

            frame.grid(row=0, column=0, sticky="nsew")

        self.show_frame(StartPage)

    def show_frame(self, cont): #cont = container

        frame = self.frames[cont]
        frame.tkraise() # Bring the frame loaded with the cont key to the front


# The code for changing pages was derived from: http://stackoverflow.com/questions/7546050/switch-between-two-frames-in-tkinter
# License: http://creativecommons.org/licenses/by-sa/3.0/	

#This is the first page used to introduce the program to the user
class StartPage(tk.Frame): #inherit everything from the frame
    def __init__(self, parent, controller):
        tk.Frame.__init__(self, parent)

        ##Title label:
        title_label = ttk.Label(self, text="DSP@Home Kit", font=HEADING_FONT) #create a label object
        title_label.grid(row=0, column=0, pady=10, padx=10, sticky="W")
        ##Initial messages:
        #Greeting message
        greetings_label = ttk.Label(self, text=GREETING_MESSAGE, font=NORMAL_FONT) #create a label object
        greetings_label.grid(row=1, column = 0, pady=10,padx=10, sticky = "W")
        #Follow up message
        follow_up_label = ttk.Label(self, text=FOLLOW_UP_MESSAGE, font=NORMAL_FONT) #create a label object
        follow_up_label.grid(row=2, column = 0, pady=10,padx=10, sticky = "W")


        ##Buttons
        #Preconfigure button
        preconfigure_button = ttk.Button(self, text="Channel setup",
                                    command=lambda: controller.show_frame(ChannelSetup))
        preconfigure_button.grid    (row=3, column = 0, pady = 5, padx = 300, sticky = "NSEW")
        #View channel button
        view_channel_button = ttk.Button(self, text="View Channel",
                                    command=lambda: controller.show_frame(GraphPage))
        view_channel_button.grid    (row=4, column = 0, pady = 5, padx = 300, sticky = "NSEW")
        #Run executable button - for external module
        #Compare channels button
        #compare_channels_button = ttk.Button(self, text="Compare Channels",
        #                            command=lambda: controller.show_frame(GraphPageCompare))
        #compare_channels_button.grid(row=5, column = 0, pady = 5, padx = 300, sticky = "NSEW")
        #Reset FPGA memory
        #reset_button = ttk.Button(self, text="Reset FPGA memory",
        #                            command=lambda: resetFPGA)
        #reset_button.grid           (row=6, column = 0, pady = 5, padx = 300, sticky = "NSEW")
        #Log Data
        #log_button = ttk.Button(self, text="Log FPGA memory",
        #                            command=lambda: controller.show_frame(LastPage))
        #log_button.grid             (row=7, column = 0, pady = 5, padx = 300, sticky = "NSEW")

        ##Basic GUI terminal
        #terminal_text = ScrolledText.ScrolledText(self, text="Terminal")
        #terminal_text.grid          (row=7, column = 0, pady = 5, padx = 5, sticky = "NSEW")

#This is the page responsible for configuring an individual channels for the FPGA DSP@Home Kit
class ChannelSetup(tk.Frame): #inherit everything from the frame
    def __init__(self, parent, controller):
        tk.Frame.__init__(self, parent)
        title_label = ttk.Label(self, text="Configuration Settings", font=HEADING_FONT) #create a label object
        title_label.grid(row=0, column = 0, pady=10, padx=10, columnspan=4)
        sampleRate = tk.IntVar()    #Stores integer value for the sample rate
        closestSampleRate = tk.DoubleVar() # Stores integer value for the nearest sample rate
        numberOfSamples = tk.IntVar()
        dataWidth = tk.StringVar()

        explanation_label = ttk.Label(self, text=CONFIG_SETUP_MESSAGE , font=NORMAL_FONT) #create a label object
        explanation_label.grid(row=1, column = 0, pady=10, padx=10, columnspan=4)

        ##Sample rate/frequency
        sampleMain_label = ttk.Label(self, text="Sample rates", font=HEADING_FONT)
        sampleMain_label.grid(row=3, column = 0, pady=10, padx=10, columnspan=4)
        sampleMainDesc_label = ttk.Label(self, text=SAMPLE_RATE_MESSAGE, font=NORMAL_FONT)
        sampleMainDesc_label.grid(row=4, column = 0, pady=10, padx=10, columnspan=4)

        sampleRate_label = ttk.Label(self, text="Sample rate[Hz]", font=NORMAL_FONT_BOLD)
        sampleRate_label.grid(row=5, column = 0, pady=10, padx=10)
        sampleRate_entry = ttk.Entry(self, font=NORMAL_FONT, textvariable=sampleRate)
        sampleRate_entry.grid(row=5, column = 1, pady=10, padx=10)

        nearestFreq_label = ttk.Label(self, text="Nearest frequency[Hz]", font=NORMAL_FONT_BOLD)
        nearestFreq_label.grid(row=5, column = 2, pady=10, padx=10)
        nearestFreqVal_label = ttk.Label(self, font=NORMAL_FONT, textvariable=closestSampleRate)
        nearestFreqVal_label.grid(row=5, column = 3, pady=10, padx=10)

        ##Number of samples
        samplesMain_label = ttk.Label(self, text="Max samples", font=HEADING_FONT)
        samplesMain_label.grid(row=7, column=0, pady=5, padx=10, columnspan=4)
        samplesMainDesc_label = ttk.Label(self, text=SAMPLES_MESSAGE, font=NORMAL_FONT)
        samplesMainDesc_label.grid(row=8, column = 0, pady=10, padx=10, columnspan=4)

        samples_label = ttk.Label(self, text="Samples", font=NORMAL_FONT_BOLD)
        samples_label.grid(row=9, column = 0, pady=10, padx=10)
        samples_entry = ttk.Entry(self, font=NORMAL_FONT, textvariable=numberOfSamples)
        samples_entry.grid(row=9, column = 1, pady=10, padx=10)

        ##Input channel data width
        choices = ['1', '16']
        dataWidthMain_label = ttk.Label(self, text="Input data width", font=HEADING_FONT)
        dataWidthMain_label.grid(row=11, column = 0, pady=10, padx=10, columnspan=4)
        dataWidthMainDesc_label = ttk.Label(self, text=INPUT_DATA_WIDTH_MESSAGE, font=NORMAL_FONT)
        dataWidthMainDesc_label.grid(row=12, column = 0, pady=10, padx=10, columnspan=4)

        dataWidth_label = ttk.Label(self, text="Data width in bits", font=NORMAL_FONT_BOLD)
        dataWidth_label.grid(row=13, column = 0, pady=10, padx=10)
        dataWidth_menu = tk.OptionMenu(self, dataWidth, *choices)
        dataWidth_menu.grid(row=13, column = 1, pady=10, padx=10)

        ##Parameter definitions
        dataWidthMain_label = ttk.Label(self, text="Parameter definitions", font=HEADING_FONT)
        dataWidthMain_label.grid(row=14, column = 0, pady=10, padx=10, columnspan=4)
        dataWidthMainDesc_label = ttk.Label(self, text=PARAMETER_MESSAGE, font=NORMAL_FONT)
        dataWidthMainDesc_label.grid(row=15, column=0, pady=10, padx=10, columnspan=4)

        #Save and exit button
        back_button = ttk.Button(self, text="Exit",
                            command=lambda: controller.show_frame(StartPage))
        back_button.grid(row=16, column = 2, columnspan=2, sticky='N')

        save_button = ttk.Button(self, text="Create parameter definitions",
                            command=lambda: calcParameters()) #lambda: controller.show_frame(StartPage)
        save_button.grid(row=17, column = 2, columnspan=2, sticky='N')

        parameterText = tk.Text(self)
        parameterText.insert(INSERT, "")
        parameterText.grid(row=16, column=0, columnspan=2, rowspan=3)

        def calcParameters():
            clk_div = round(100000000/sampleRate.get()) #Rounds to the nearest frequency
            doubleNearestFreq = 100000000/clk_div
            closestSampleRate.set(doubleNearestFreq)
            data_depth = math.ceil((numberOfSamples.get())*(int(dataWidth.get())/16)) #Address size for memory buffers
            address_size = data_depth.bit_length()
            parameterText.delete(1.0, END)
            parameterText.insert(END, ".NO_OF_SAMPLES("+str(numberOfSamples.get())+"),\n"
                                    + ".CLK_DIV("+str(clk_div)+"),\n"
                                    + ".DATA_WIDTH(16),\n"
                                    + ".DATA_DEPTH("+str(data_depth)+"),\n"
                                    + ".ADDRESS_SIZE("+str(address_size)+"),\n"
                                    + ".ALMOST_EMPTY_THRESH("+str(round(0.2*data_depth))+"),\n"
                                    + ".ALMOST_FULL_THRESH("+str(round(0.8*data_depth))+")"
                                 )

        #ADD A WARNING MESSAGE ABOUT THE FAILING DDR2 IMPLEMENTATION

#This is the page responsible for configuring pre-exisiting channels for the FPGA DSP@Home Kit.
#This includes setting the channel sampling rate, resetting the channel and to read data.

class GraphPage(tk.Frame): #inherit everything from the frame
    def __init__(self, parent, controller):
        tk.Frame.__init__(self, parent)
        #Tkinter variables
        fileName = tk.StringVar()
        readChannel = tk.StringVar()
        numberOfSamples = tk.StringVar()
        frequency = tk.StringVar()
        digitalOrAnalog = tk.StringVar()
        #Default values - User must set these to the corresponding channel settings on the FPGA
        readChannel.set('1')
        fileName.set('channel1Data')
        numberOfSamples.set('1000')
        frequency.set('1000')
        digitalOrAnalog.set('Digital (1 bit)')

        #Row values (for easier editing)
        label_row = 2

        ##Page Title
        label = ttk.Label(self, text="Graph Page", font=HEADING_FONT) #Create a label object
        label.grid(row=0, column=0, pady=10, sticky='N', columnspan=5)
        #Read channel section
        readChannel_label = ttk.Label(self, text="Read channel: ", font=NORMAL_FONT_BOLD)  # Create a label object
        readChannel_entry = tk.Entry(self, font=NORMAL_FONT, textvariable=readChannel)
        readChannel_label.grid(row=label_row, column=0, pady=2, padx=10)
        readChannel_entry.grid(row=label_row+1, column=0, pady=2)
        # File name section
        dir_label = ttk.Label(self, text="File name: ", font=NORMAL_FONT_BOLD)  # Create a label object
        dir_entry = tk.Entry(self, font=NORMAL_FONT, textvariable=fileName)
        dir_label.grid(row=label_row, column=1, pady=2, padx=10)
        dir_entry.grid(row=label_row+1, column=1, pady=2)
        # Samples section
        samples_label = ttk.Label(self, text="Samples: ", font=NORMAL_FONT_BOLD)  # Create a label object
        samples_entry = tk.Entry(self, font=NORMAL_FONT, textvariable=numberOfSamples)
        samples_label.grid(row=label_row, column=2, pady=2, padx=10)
        samples_entry.grid(row=label_row+1, column=2, pady=2)
        # Frequency
        freq_label = ttk.Label(self, text="Frequency: ", font=NORMAL_FONT_BOLD)  # Create a label object
        freq_entry = tk.Entry(self, font=NORMAL_FONT, textvariable=frequency)
        freq_label.grid(row=label_row, column=3, pady=2, padx=10)
        freq_entry.grid(row=label_row+1, column=3, pady=2)
        # Frequency
        freq_label = ttk.Label(self, text="Frequency: ", font=NORMAL_FONT_BOLD)  # Create a label object
        freq_entry = tk.Entry(self, font=NORMAL_FONT, textvariable=frequency)
        freq_label.grid(row=label_row, column=3, pady=2, padx=10)
        freq_entry.grid(row=label_row+1, column=3, pady=2)
        # Digital or analog
        choices = ['Digital (1 bit)', 'Analog (16 bit)']
        digitalOrAnalog_label = ttk.Label(self, text="Digital/Analog Select: ", font=NORMAL_FONT_BOLD)  # Create a label object
        digitalOrAnalog_option = tk.OptionMenu(self, digitalOrAnalog, *choices)
        digitalOrAnalog_label.grid(row=label_row, column=4, pady=2, padx=10)
        digitalOrAnalog_option.grid(row=label_row+1, column=4, pady=2)
        ##Buttons
        loadData_button = ttk.Button(self, text="Open csv file",
                                     command=lambda: loadCSV())
        loadData_button.grid(row=label_row+2, column=0, pady=10, padx=5, sticky='NSEW')

        readFPGA_button = ttk.Button(self, text="Read FPGA",
                                     command=lambda: controller.show_frame(StartPage))
        readFPGA_button.grid(row=label_row+3, column=0, pady=10, padx=5, sticky='NSEW')

        exit_button = ttk.Button(self, text="Exit",
                                 command=lambda: controller.show_frame(StartPage))
        exit_button.grid(row=label_row+4, column=0, pady=10, padx=5, sticky='NSEW')

        ##Graph figure
        graphFigure = Figure(figsize=(11, 8), dpi=100)
        a = graphFigure.add_subplot(111)  # 1 subplot, 1 chart
        a.plot([1, 2, 3, 4, 5, 6, 7, 8], [2, 4, 6, 8, 2, 4, 6, 8])
        a.set_xlabel("Time (seconds)")
        a.set_ylabel("Value")
        graphFigure.suptitle("Recorded channel data") #Read data

        canvas = FigureCanvasTkAgg(graphFigure, self)
        #canvas.draw()
        canvas.get_tk_widget().grid(row=label_row+5, column=1, columnspan=5, rowspan=8)

        toolbarFrame = tk.Frame(self)
        toolbarFrame.grid(row=16, column=1, columnspan=5)

        toolbar = NavigationToolbar2Tk(canvas, toolbarFrame)
        toolbar.update()
        canvas.get_tk_widget().grid(row=label_row+2, column=1, columnspan=5)

        def loadCSV():
            #print("Hello")
            self.filename = tk.filedialog.askopenfilename(initialdir="/", title="Select A File", filetypes=(("csv files", "*.csv"),("all files", "*.*")))
            if digitalOrAnalog.get() == 'Analog (16 bit)':
                data = fpgaFileHandler.interpretAsAnalogCSV(self.filename)
            else:
                data = fpgaFileHandler.interpretAsDigitalCSV(self.filename)

            fileName.set(os.path.basename(self.filename)) #Extract file name from the path
            readChannel.set(data[0][0])
            numberOfSamples.set(data[0][2])
            frequency.set(data[0][1])

            a.clear()
            #print(data[1])
            a.plot(data[1], data[2])
            a.set_xlabel("Time (seconds)")
            a.set_ylabel("Sample Value")
            graphFigure.suptitle("Recorded channel data")  # Read data
            canvas.draw()

app = DSPHomeKit()

if __name__ == '__main__':
    app.mainloop()

#Notes
# Lambda - create a throw away function, runs only immediately when it is executed.


