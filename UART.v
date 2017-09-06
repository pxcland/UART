/*	UART.v
	Top level module that ties the receiver and transmitter together
	
	Copyright 2017 Patrick Cland */

`timescale 1ns / 1ps
module UART(CLK, RST, BaudRate, ParityMode, StopBits, Tx, Rx, Error);
    input CLK;
    input RST;
    input[1:0] BaudRate;
    input[1:0] ParityMode;
    input StopBits;
    output Tx;
    input Rx;
    output Error;
    
    wire TxBusy;
    
    wire[7:0] RxData;
    wire RxDataReady;
    
    Transmitter T1( .CLK(CLK), 
                    .RST(RST), 
                    .BaudRate(BaudRate), 
                    .ParityMode(ParityMode), 
                    .StopBits(StopBits),
                    .TxBegin(RxDataReady),
                    .TxData(RxData),
                    .TxBusy(TxBusy),
                    .Tx(Tx));
                    
    Receiver R1(    .CLK(CLK),
                    .RST(RST),
                    .BaudRate(BaudRate),
                    .ParityMode(ParityMode),
                    .StopBits(StopBits),
                    .Rx(Rx),
                    .RxData(RxData),
                    .RxDataReady(RxDataReady),
                    .Error(Error));
                    
endmodule