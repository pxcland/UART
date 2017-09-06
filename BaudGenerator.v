/*	BaudGenerator.v
	Generates a pulse at the specified rate from a 100MHz clock
	
	Copyright 2017 Patrick Cland */
`timescale 1ns / 1ps
module BaudGeneratorTx(CLK, RST, BaudRate, Pulse);
    input CLK;
    input RST;
    input[1:0] BaudRate;
    output reg Pulse;
    
    reg[18:0] Counter; //19 bits needed to count to 333333

    //00 - 300 Baud     - 100MHz clock, count to 333333
    //01 - 9600 Baud    - count to 10417
    //10 - 38400 Baud   - count to 2604
    //11 - 115200 Baud  - count to 868
    always @ (posedge CLK or posedge RST) begin
        if(RST) begin
            Pulse <= 1'b0;
            Counter <= 19'b0;
        end else begin
            case(BaudRate)
                2'b00: begin
                    Counter <= Counter + 19'b1;
                    if(Counter == 19'd333333) begin
                        Pulse <= 1'b1;
                        Counter <= 19'b0;
                    end else begin
                        Pulse <= 1'b0;
                    end
                end
                2'b01: begin
                    Counter <= Counter + 19'b1;
                    if(Counter == 19'd10417) begin
                        Pulse <= 1'b1;
                        Counter <= 19'b0;
                    end else begin
                        Pulse <= 1'b0;
                    end
                end
                2'b10: begin
                    Counter <= Counter + 19'b1;
                    if(Counter == 19'd2604) begin
                        Pulse <= 1'b1;
                        Counter <= 19'b0;
                    end else begin
                        Pulse <= 1'b0;
                    end
                end
                2'b11: begin
                    Counter <= Counter + 19'b1;
                    if(Counter == 19'd868) begin
                        Pulse <= 1'b1;
                        Counter <= 19'b0;
                    end else begin
                        Pulse <= 1'b0;
                    end
                end
            endcase
        end
    end
endmodule

module BaudGeneratorRx(CLK, RST, BaudRate, Pulse);
    input CLK;
    input RST;
    input[1:0] BaudRate;
    output reg Pulse;
    
    reg[14:0] Counter; //15 bits needed to count to 20833
    //Sampling at 16x rate of Tx
    //00 - 300      20833
    //01 - 9600     651
    //10 - 38400    163  
    //11 - 115200   54
    always @ (posedge CLK or posedge RST) begin
        if(RST) begin
            Pulse <= 1'b0;
            Counter <= 15'b0;
        end else begin
            case(BaudRate)
                2'b00: begin
                    Counter <= Counter + 15'b1;
                    if(Counter == 15'd20833) begin
                        Pulse <= 1'b1;
                        Counter <= 15'b0;
                    end else begin
                        Pulse <= 1'b0;
                    end
                end
                2'b01: begin
                    Counter <= Counter + 15'b1;
                    if(Counter == 15'd651) begin
                        Pulse <= 1'b1;
                        Counter <= 15'b0;
                    end else begin
                        Pulse <= 1'b0;
                    end
                end
                2'b10: begin
                    Counter <= Counter + 15'b1;
                    if(Counter == 15'd163) begin
                        Pulse <= 1'b1;
                        Counter <= 15'b0;
                    end else begin
                        Pulse <= 1'b0;
                    end
                end
                2'b11: begin
                    Counter <= Counter + 15'b1;
                    if(Counter == 15'd54) begin
                        Pulse <= 1'b1;
                        Counter <= 15'b0;
                    end else begin
                        Pulse <= 1'b0;
                    end
                end
            endcase
        end
    end
endmodule