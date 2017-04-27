`timescale 1 ns / 1 ps

// Read-Modify-Write, dual port synchronous RAM
module bram_rti (
    input clk, ena, enb, wea, web,
    input [11:0] addra, addrb,
    input [47:0] dia, dib,
    output [47:0] doa, dob
);

    reg [47:0] ram [4095:0];
    reg [47:0] doa, dob;

    always @(posedge clk) begin
        if (ena) begin
            if (wea)
                ram[addra] <= dia;
            doa <= ram[addra];
        end
        if (enb) begin
            if (web)
                ram[addrb] <= dib;
            dob <= ram[addrb];
        end
    end

endmodule
