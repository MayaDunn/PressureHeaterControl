# PressureHeaterControl
MATLAB Code to control the pressure of a liquid helium cooled chamber using a heater using a PID loop.

This code modifies the PID loop to never request negative heating, and to never heat above 45% of what the heater is capable of.

In order to use this code you must supply the function 'lakeshoreQuery()' which communicates querys to the heater. 
I have chosen to emit this function as I did not write the one I used, and the function needs to be written for a specific heater.
