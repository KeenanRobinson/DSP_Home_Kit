/******************************************************************************
Code description
This is just a code base that I have used to mock test certain functions to 
ensure proper functioning of logic. This is not to be used in the driver. This
was executed on https://www.onlinegdb.com/online_c_compiler to test the logic.


*******************************************************************************/

//Simulation: Test the testControlPin() logic
#include <stdio.h>

int main()
{
    int ctl = 0b10100110;
    int reg = 0b11110010;
    int onOff=0;
    if(onOff) {
        ctl = (ctl & 0xF0) | (reg & 0xF);
    }
    else {
        ctl = ctl & ~(reg & 0xF);
    }
    printf("Ctl: %d", ctl);
}                                                                                                    }
