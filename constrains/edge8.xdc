## =========================================================
## EdgeStreamTop - Nexys A7-100T minimal constraints
## Top ports:
##   iClk
##   iRsn
##   iUartRx
##   oUartTx
## =========================================================

## 100 MHz board clock
set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 } [get_ports { iClk }]
create_clock -name sys_clk -period 10.000 [get_ports { iClk }]

## Reset / enable switch (SW0)
## Board switch is active-high. Use this as iRsn if desired.
set_property -dict { PACKAGE_PIN J15 IOSTANDARD LVCMOS33 } [get_ports { iRsn }]

## USB-UART interface
## PC TX -> FPGA RX
set_property -dict { PACKAGE_PIN C4 IOSTANDARD LVCMOS33 } [get_ports { iUartRx }]

## FPGA TX -> PC RX
set_property -dict { PACKAGE_PIN D4 IOSTANDARD LVCMOS33 } [get_ports { oUartTx }]