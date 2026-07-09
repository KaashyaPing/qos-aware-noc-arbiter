`timescale 1ns/1ps

module tb_starvation;

reg clk;
reg reset;
reg [3:0] req;
wire [3:0] grant;

//---------------- APB ----------------
reg        PSEL;
reg        PENABLE;
reg        PWRITE;
reg [7:0]  PADDR;
reg [31:0] PWDATA;
wire [31:0] PRDATA;
wire       PREADY;

//---------------- DUT ----------------
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

// Clock
always #5 clk = ~clk;

initial begin

    $dumpfile("starvation.vcd");
    $dumpvars(0, tb_starvation);

    clk = 0;
    reset = 1;

    req = 4'b0000;

    PSEL = 0;
    PENABLE = 0;
    PWRITE = 0;
    PADDR = 0;
    PWDATA = 0;

    #20;
    reset = 0;

    //-------------------------------------------------
    // Force requester 3 to wait
    //-------------------------------------------------

    req = 4'b1001;

    repeat(20)
        @(posedge clk);

    $finish;

end

endmodule