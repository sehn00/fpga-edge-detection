# FPGA Edge Detection

FPGA-based streaming image processing pipeline that receives RGB pixel data over UART, converts it to grayscale, applies Sobel edge detection, and transmits the processed output back through UART.

## Overview
This project implements a hardware image-processing pipeline on FPGA for real-time edge detection.  
The input RGB pixel stream is received through UART, processed stage by stage in hardware, and the resulting edge-detected output is transmitted back through UART.

## Features
- UART-based RGB pixel input
- Grayscale conversion
- Sobel edge detection
- UART-based processed output transmission
- Streaming pipeline architecture for hardware-based image processing

## Notice
This repository is provided for viewing purposes only.

All rights reserved.

No permission is granted to use, copy, modify, distribute, or create derivative works from this code without explicit prior permission from the author.
