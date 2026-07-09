`timescale 1ns/1ps

module tb_apb_write;

reg clk;
reg reset;
reg [3:0] req;

reg PSEL;
reg PENABLE;
reg PWRITE;
reg [7:0] PADDR;
reg [31:0] PWDATA;

wire [3:0] grant;
wire [31:0] PRDATA;
wire PREADY;

arbiter DUT (
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

//--------------------------------------------------
// Clock Generation
//--------------------------------------------------
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

//--------------------------------------------------
// APB Write Task
//--------------------------------------------------
task apb_write;
    input [7:0] addr;
    input [31:0] data;
begin

    @(posedge clk);
    PSEL    <= 1'b1;
    PENABLE <= 1'b0;
    PWRITE  <= 1'b1;
    PADDR   <= addr;
    PWDATA  <= data;

    @(posedge clk);
    PENABLE <= 1'b1;

    @(posedge clk);
    PSEL    <= 1'b0;
    PENABLE <= 1'b0;
    PWRITE  <= 1'b0;
    PADDR   <= 8'h00;
    PWDATA  <= 32'h00000000;

end
endtask

//--------------------------------------------------
// Waveform Dump
//--------------------------------------------------
initial begin
    $dumpfile("apb_write.vcd");
    $dumpvars(0, tb_apb_write);
end

//--------------------------------------------------
// Test Sequence
//--------------------------------------------------
initial begin

    reset   = 1'b1;
    req     = 4'b0000;

    PSEL    = 0;
    PENABLE = 0;
    PWRITE  = 0;
    PADDR   = 0;
    PWDATA  = 0;

    #20;
    reset = 0;

    // Program QoS Priorities
    apb_write(8'h00, 32'd3);
    apb_write(8'h04, 32'd2);
    apb_write(8'h08, 32'd1);
    apb_write(8'h0C, 32'd0);

    // Program Age Limit
    apb_write(8'h10, 32'd8);

    // Program Congestion Threshold
    apb_write(8'h14, 32'd3);

    #40;

    $finish;

end

//--------------------------------------------------
// Console Monitor
//--------------------------------------------------
initial begin
    $display("---------------------------------------------------------------");
    $display(" Time    PSEL PENABLE PWRITE   PADDR     PWDATA        PREADY");
    $display("---------------------------------------------------------------");

    $monitor("%5t      %b      %b       %b     0x%02h   0x%08h     %b",
        $time,
        PSEL,
        PENABLE,
        PWRITE,
        PADDR,
        PWDATA,
        PREADY);
end

endmodule