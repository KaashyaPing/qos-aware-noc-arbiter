`timescale 1ns/1ps

module tb_round_robin;

reg clk;
reg reset;
reg [3:0] req;
wire [3:0] grant;

// --------------------
// Dummy APB signals
// --------------------

reg PSEL;
reg PENABLE;
reg PWRITE;
reg [7:0] PADDR;
reg [31:0] PWDATA;

wire [31:0] PRDATA;
wire PREADY;

// --------------------
// Instantiate Arbiter
// --------------------

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

// --------------------
// Clock Generation
// --------------------

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin
    $monitor(
        "T=%0t Req=%b Grant=%b Pointer=%0d",
        $time,
        req,
        grant,
        uut.pointer
    );
end

// --------------------
// VCD Dump
// --------------------

initial begin
    $dumpfile("round_robin.vcd");
    $dumpvars(0, tb_round_robin);
end;

// --------------------
// Stimulus
// --------------------

initial begin

    reset = 1;

    req = 4'b0000;

    PSEL = 0;
    PENABLE = 0;
    PWRITE = 0;
    PADDR = 0;
    PWDATA = 0;

    #20;

    reset = 0;

    // Single requester
    req = 4'b0001;
    #20;

    req = 4'b0010;
    #20;

    req = 4'b0100;
    #20;

    req = 4'b1000;
    #20;

    // All request simultaneously
    req = 4'b1111;
    #120;

    $finish;

end

endmodule