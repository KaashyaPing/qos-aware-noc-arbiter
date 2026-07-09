`timescale 1ns/1ps

module tb_round_robin;

reg clk;
reg reset;
reg [3:0] req;
wire [3:0] grant;

//-------------------------
// APB Interface
//-------------------------

reg PSEL;
reg PENABLE;
reg PWRITE;
reg [7:0] PADDR;
reg [31:0] PWDATA;

wire [31:0] PRDATA;
wire PREADY;

//-------------------------
// DUT
//-------------------------

arbiter uut(
    .clk(clk),
    .reset(reset),
    .req(req),
    .grant(grant),

    .PSEL(PSEL),
    .PENABLE(PENABLE),
    .PWRITE(PWRITE),
    .PADDR(PADDR),
    .PWDATA(PWDATA),
    .PRDATA(PRDATA),
    .PREADY(PREADY)
);

//-------------------------
// Clock
//-------------------------

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

//-------------------------
// Waveform
//-------------------------

initial begin
    $dumpfile("round_robin.vcd");
    $dumpvars(0, tb_round_robin);
end

//-------------------------
// Monitor
//-------------------------

initial begin
    $monitor(
        "T=%0t  Pointer=%0d  Req=%b  Grant=%b",
        $time,
        uut.pointer,
        req,
        grant
    );
end

//-------------------------
// APB Write Task
//-------------------------

task apb_write;

input [7:0] addr;
input [31:0] data;

begin

    @(posedge clk);

    PSEL    = 1;
    PENABLE = 1;
    PWRITE  = 1;
    PADDR   = addr;
    PWDATA  = data;

    @(posedge clk);

    PSEL    = 0;
    PENABLE = 0;
    PWRITE  = 0;

end

endtask

//-------------------------
// Stimulus
//-------------------------

initial begin

    reset   = 1;
    req     = 4'b0000;

    PSEL    = 0;
    PENABLE = 0;
    PWRITE  = 0;
    PADDR   = 0;
    PWDATA  = 0;

    #20;

    reset = 0;

    //-------------------------------------------------
    // Make all priorities equal
    //-------------------------------------------------

    apb_write(8'h00,32'd3);
    apb_write(8'h04,32'd3);
    apb_write(8'h08,32'd3);
    apb_write(8'h0C,32'd3);

    //-------------------------------------------------
    // All request simultaneously
    //-------------------------------------------------

    req = 4'b1111;

    #160;

    req = 4'b0000;

    #20;

    $finish;

end

endmodule