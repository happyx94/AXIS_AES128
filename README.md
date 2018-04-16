AXIS_AES128
=======
A synthesizable VHDL implementation of AES128 encryptor in CBC mode with AXI4 
Stream Interface and a seperate AXI-Lite interface for key and IV input. 


Example Design
-------
An example implementation using AXI-DMA for AES Encryptor to PS communication
on ZYNQ 7007S of the MiniZed developement board is shown here:

![Alt text](/schematics/overview.png?raw=true "Top-level Schematic")


![Alt text](/schematics/AES-DMA.png?raw=true "Top-level Schematic")



Reference
-------
The source code of AES encryption components are adapted from 

https://github.com/mbgh/aes128-hdl


