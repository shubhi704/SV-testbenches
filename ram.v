`timescale 1ns/1ns
module ram(input clk,rst,we,
           input [7:0]addr,
           input [7:0] dataIn,
           output reg[7:0] dataOut );
integer i;
  
 reg [7:0]mem [0:7];

           always @(posedge clk) begin
            if(rst == 1'b1) begin
              for(i=0;i<256; i++) begin
                 mem[addr] <= 8'd0;
                 end
                 end
            else if(rst == 1'b0) begin
             if(we)
              mem[addr] <= dataIn;
             else
              dataOut <= mem[addr];
            end
            end
        endmodule 
