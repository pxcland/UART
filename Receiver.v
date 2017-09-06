/*	Receiver.v
	Receives data over serial connection and generates parallel data output
	
	Copyright 2017 Patrick Cland */
`timescale 1ns / 1ps
module Receiver(CLK, RST, BaudRate, ParityMode, StopBits, Rx, RxData, RxDataReady, Error);
    input CLK;
    input RST;
    input[1:0] BaudRate;
    input[1:0] ParityMode; //00 - Even, 01 - Odd, 1X - No parity
    input StopBits; //0 - 1 bit, 1 - 2 bits
    input Rx;
    output reg[7:0] RxData;
    output reg RxDataReady;
    output reg Error;
    
    wire BaudPulse;
    reg SampleBit; //Asserted every 16 BaudPulses after initial 8 for start bit
    reg[2:0] EstablishSampleCounter; //To count to 8;
    reg[3:0] SampleCounter; //To count to 16
    
    reg RxSync;
    reg RxPrev;
    reg RxBusy;
    reg RxSampling;
    
    reg RxParity;
    
    reg[3:0] State;
    
    BaudGeneratorRx B1(.CLK(CLK), .RST(RST), .BaudRate(BaudRate), .Pulse(BaudPulse));
    
    //Synchronize Rx
    always @ (posedge CLK or posedge RST) begin
        if(RST) begin
            RxSync <= 1'b0;
            RxPrev <= 1'b0;
        end else begin
            if(BaudPulse) begin 
                RxSync <= Rx;
                RxPrev <= RxSync;
            end
        end
    end
    
    always @ (posedge CLK or posedge RST) begin
        if(RST) begin
            State <= 4'b0000;
            RxBusy <= 1'b0;
            RxSampling <= 1'b0;
            RxDataReady <= 1'b0;
            RxData <= 8'd0;
            EstablishSampleCounter <= 3'd0;
            SampleCounter <= 4'd0;
            SampleBit <= 1'b0;
            Error <= 1'b0;
            RxParity <= 1'b0;
        end else begin
            //Falling edge of start bit
            if(~RxSync && RxPrev && ~RxBusy) begin 
                RxBusy <= 1'b1; //Now we are receiving data
            end else begin
                RxBusy <= RxBusy;
            end
            //When we commence Receiving but haven't established the sampling point yet
            if(RxBusy && ~RxSampling) begin 
                if(BaudPulse) begin
                    EstablishSampleCounter <= EstablishSampleCounter + 3'b1;
                    if(EstablishSampleCounter == 3'b111) begin //Wait 8 cycles to establish middle of each bit
                        RxSampling <= 1'b1;
                    end else begin
                        RxSampling <= 1'b0;
                    end
                end
            end
            //Generate pulse every 16 baud to get sample
            if(RxSampling) begin
                if(BaudPulse) begin
                    SampleCounter <= SampleCounter + 4'b1;
                    SampleBit <= (SampleCounter == 4'b1111);
                end
            end
            
            if(BaudPulse) begin
                case(State)
                    4'b0000: begin 
                        if(RxSampling && RxBusy) State <= 4'b0001; //Start bit
                        RxDataReady <= 1'b0;
                    end
                    4'b0001: begin 
                        if(SampleBit) State <= 4'b0010;    //Bit 0
                        RxData[0] <= RxSync;
                    end
                    4'b0010: begin 
                        if(SampleBit) State <= 4'b0011;    //Bit 1
                        RxData[1] <= RxSync;
                    end
                    4'b0011: begin 
                        if(SampleBit) State <= 4'b0100;
                        RxData[2] <= RxSync;
                    end
                    4'b0100: begin 
                        if(SampleBit) State <= 4'b0101;
                        RxData[3] <= RxSync;
                    end
                    4'b0101: begin 
                        if(SampleBit) State <= 4'b0110;
                        RxData[4] <= RxSync;
                    end
                    4'b0110: begin 
                        if(SampleBit) State <= 4'b0111;
                        RxData[5] <= RxSync;
                    end
                    4'b0111: begin 
                        if(SampleBit) State <= 4'b1000;
                        RxData[6] <= RxSync;
                    end
                    4'b1000: begin //Bit 7
                        if(SampleBit) begin   
                            if(ParityMode[1] == 1'b1) begin //No parity
                                State <= 4'b1010; //go straight to stop bit
                            end else begin
                                State <= 4'b1001; //get parity bit
                            end
                        end
                        RxData[7] <= RxSync;
                    end
                    4'b1001: begin //Parity
                        if(SampleBit) State <= 4'b1010; //go to stop bit
                        RxParity <= RxSync;
                    end
                    4'b1010: begin  //Stop bit 1
                        if(StopBits == 1'b0) begin //only 1 stop bit
                            State <= 4'b0000;    
                            RxDataReady <= 1'b1;
                            RxBusy <= 1'b0;
                            RxSampling <= 1'b0;
                            if(ParityMode == 2'b00) begin //Even Parity
                                Error <= ((RxData[0] ^ RxData[1]) ^ (RxData[2] ^ RxData[3])) ^ ((RxData[4] ^ RxData[5]) ^ (RxData[6] ^ RxData[7])) ^ RxParity;
                            end else if(ParityMode == 2'b01) begin //Odd Parity
                                Error <= (~((RxData[0] ^ RxData[1]) ^ (RxData[2] ^ RxData[3])) ^ ((RxData[4] ^ RxData[5]) ^ (RxData[6] ^ RxData[7])) ^ RxParity);
                            end else begin
                                Error <= 1'b0;
                            end
                        end else begin //Get another stop bit
                            if(SampleBit) State <= 4'b1011;
                        end
                    end
                    4'b1011: begin  //stop bit 2
                        State <= 4'b0000;    
                        RxDataReady <= 1'b1;
                        RxBusy <= 1'b0;
                        RxSampling <= 1'b0;
                        if(ParityMode == 2'b00) begin //Even Parity
                            Error <= ((RxData[0] ^ RxData[1]) ^ (RxData[2] ^ RxData[3])) ^ ((RxData[4] ^ RxData[5]) ^ (RxData[6] ^ RxData[7])) ^ RxParity;
                        end else if(ParityMode == 2'b01) begin //Odd Parity
                            Error <= (~((RxData[0] ^ RxData[1]) ^ (RxData[2] ^ RxData[3])) ^ ((RxData[4] ^ RxData[5]) ^ (RxData[6] ^ RxData[7])) ^ RxParity);
                        end else begin
                            Error <= 1'b0;
                        end
                    end
                    default: begin 
                        State <= 4'b0000;
                    end
                endcase
            end
        end
    end
 
endmodule