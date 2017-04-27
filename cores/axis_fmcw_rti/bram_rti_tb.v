`timescale 1 ns / 1 ps;

module bram_rti_tb ();

    reg clk, ena, enb, wea, web;
    wire [11:0] addra, addrb;
    wire [23:0] dia, dib, comb;
    wire [23:0] doa, dob;

    reg [11:0] addr, addr_reg;
    reg [23:0] data_in, data_out;
    reg toggle, toggle_next;
    reg rstn;

    localparam SIZE = 4096;

    bram_rti ram(clk, ena, enb, wea, web, addra, addrb, dia, dib, doa, dob);

    assign addra = addr;
    assign addrb = addr_reg;
    assign dia = 24'bz;
    assign comb = (doa + data_in) >> 1;
    assign dib = (toggle) ? comb : data_in;

    initial begin
        clk = 0;
        ena = 0;
        enb = 0;
        wea = 0;
        web = 0;
        rstn = 0;
        #10 rstn = 1;
        ena = 1;
        enb = 1;
        #60000 $finish;
    end

    always
        #1 clk = ~clk;

    always @(posedge clk) begin
        if (~rstn) begin
            addr <= 0;
            addr_reg <= 0;
            data_in <= 0;
            toggle <= 0;
            toggle_next <= 0;
            web <= 0;
        end
        else begin
            web <= 1;
            if (addr == SIZE-1) begin
                addr <= 0;
                toggle_next <= ~toggle;
            end
            else
                addr <= addr + 1;
            addr_reg <= addr;
            data_in <= data_in + 1;
            data_out <= dob;
            toggle <= toggle_next;
        end
    end

endmodule
