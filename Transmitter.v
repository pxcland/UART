/*	Transmitter.v
	Serializes data and outputs at baud rate and specified settings over serial port
	
	Copyright 2017 Patrick Cland */
`timescale 1ns / 1ps
module Transmitter(CLK, RST, BaudRate, ParityMode, StopBits, TxBegin, TxData, TxBusy, Tx);
    input CLK;
    input RST;
    input[1:0] BaudRate;
    input[1:0] ParityMode;  //00 - Even, 01 - Odd, 1X - No parity
    input StopBits; //0 - 1 bit, 1 - 2 bits
    input TxBegin;
    input[7:0] TxData;
    output reg TxBusy;
    output reg Tx;
    
    wire BaudPulse;
    reg[3:0] State; //How far we are on sending each packet
    reg TxBeginPending;
    reg[7:0] TxDataS; //Updated when data will be serialized, synchronous to the TxBegin and ~TxBusy signal
        
    BaudGeneratorTx B1(.CLK(CLK), .RST(RST), .BaudRate(BaudRate), .Pulse(BaudPulse));
    
    always @ (posedge CLK) begin
        if(TxBegin && ~TxBusy) TxDataS <= TxData;
        else TxDataS <= TxDataS;
    end
    
    always @ (posedge CLK or posedge RST) begin
        if(RST) begin
            State <= 4'b0000;
            TxBeginPending <= 1'b0;
        end else begin
            if(TxBegin) TxBeginPending <= 1'b1; //Guarantee to send the start bit of the packet on a baud pulse
            case(State)
                4'b0000: if(TxBeginPending & BaudPulse) begin State <= 4'b0001; TxBeginPending <= 1'b0; end //Begin sending packet on baud pulse
                4'b0001: if(BaudPulse) State <= 4'b0010; //Send start bit
                4'b0010: if(BaudPulse) State <= 4'b0011; //Send bit 0
                4'b0011: if(BaudPulse) State <= 4'b0100; //Send bit 1
                4'b0100: if(BaudPulse) State <= 4'b0101; //Send bit 2
                4'b0101: if(BaudPulse) State <= 4'b0110; //Send bit 3
                4'b0110: if(BaudPulse) State <= 4'b0111; //Send bit 4
                4'b0111: if(BaudPulse) State <= 4'b1000; //Send bit 5
                4'b1000: if(BaudPulse) State <= 4'b1001; //Send bit 6
                4'b1001: begin //Send bit 7
                    if(BaudPulse) begin 
                        if(ParityMode[1] == 1'b1) State <= 4'b1010; // no parity, go straight to stop bit
                        else State <= 4'b1100; //parity, go to send parity bit
                    end
                end
                4'b1010: begin //Send first stop bit
                    if(BaudPulse) begin
                        if(StopBits == 1'b0) State <= 4'b0000; //1 stop bit, we're finished
                        if(StopBits == 1'b1) State <= 4'b1011; //2 stop bits, send another
                    end
                end
                4'b1011: if(BaudPulse) State <= 4'b0000; //send last stop bit, we're finished
                4'b1100: if(BaudPulse) State <= 4'b1010; //send parity bit, then go to stop bit
                default: State <= 4'b0000;
            endcase
        end
    end
    
    always @ (State or TxDataS or ParityMode) begin
        case(State)
            4'b0001: Tx <= 1'b0;        //Send start bit
            4'b0010: Tx <= TxDataS[0];   //Send first data bit
            4'b0011: Tx <= TxDataS[1];
            4'b0100: Tx <= TxDataS[2];
            4'b0101: Tx <= TxDataS[3];
            4'b0110: Tx <= TxDataS[4];
            4'b0111: Tx <= TxDataS[5];
            4'b1000: Tx <= TxDataS[6];
            4'b1001: Tx <= TxDataS[7];   //send last data bit
            4'b1010: Tx <= 1'b1;        //Send first stop bit
            4'b1011: Tx <= 1'b1;        //Send last stop bit
            4'b1100: begin              //Send parity bit
                if(ParityMode[0] == 1'b0) begin //even
                    Tx <= (TxDataS[7] ^ (TxDataS[6] ^ (TxDataS[5] ^ (TxDataS[4] ^ (TxDataS[3] ^ (TxDataS[2] ^ (TxDataS[1] ^ (TxDataS[0]))))))));
                end else begin //odd
                    Tx <= ~(TxDataS[7] ^ (TxDataS[6] ^ (TxDataS[5] ^ (TxDataS[4] ^ (TxDataS[3] ^ (TxDataS[2] ^ (TxDataS[1] ^ (TxDataS[0]))))))));
                end
            end
            default: Tx <= 1'b1;        //Anything else forces line to be idle
        endcase
    end
    
    always @ (State) begin
        case(State)
            4'b0000: TxBusy <= 1'b0;    //When not serializing and sending, not busy
            4'b1101: TxBusy <= 1'b0;
            4'b1110: TxBusy <= 1'b0;
            4'b1111: TxBusy <= 1'b0;
            default: TxBusy <= 1'b1;
        endcase
    end
endmodule