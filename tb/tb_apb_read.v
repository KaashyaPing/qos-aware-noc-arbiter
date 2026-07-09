`timescale 1ns/1ps

module tb_apb_read;

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
// Clock
//--------------------------------------------------
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

//--------------------------------------------------
// APB WRITE TASK
//--------------------------------------------------
task apb_write;
input [7:0] addr;
input [31:0] data;
begin

    @(posedge clk);
    PSEL    <= 1;
    PENABLE <= 0;
    PWRITE  <= 1;
    PADDR   <= addr;
    PWDATA  <= data;

    @(posedge clk);
    PENABLE <= 1;

    @(posedge clk);
    PSEL    <= 0;
    PENABLE <= 0;
    PWRITE  <= 0;
    PADDR   <= 0;
    PWDATA  <= 0;

end
endtask

//--------------------------------------------------
// APB READ TASK
//--------------------------------------------------
task apb_read;
input [7:0] addr;
begin

    @(posedge clk);
    PSEL    <= 1;
    PENABLE <= 0;
    PWRITE  <= 0;
    PADDR   <= addr;

    @(posedge clk);
    PENABLE <= 1;

    @(posedge clk);

    $display("Time=%0t  READ  Addr=0x%02h  Data=0x%08h",
              $time, addr, PRDATA);

    PSEL    <= 0;
    PENABLE <= 0;
    PADDR   <= 0;

end
endtask

//--------------------------------------------------
// Dump
//--------------------------------------------------
initial begin
    $dumpfile("apb_read.vcd");
    $dumpvars(0,tb_apb_read);
end

//--------------------------------------------------
// Test
//--------------------------------------------------
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

    //--------------------------------------------------
    // Program Registers
    //--------------------------------------------------

    apb_write(8'h00,32'd3);
    apb_write(8'h04,32'd2);
    apb_write(8'h08,32'd1);
    apb_write(8'h0C,32'd0);

    apb_write(8'h10,32'd8);
    apb_write(8'h14,32'd3);

    //--------------------------------------------------
    // Generate Some Activity
    //--------------------------------------------------

    req = 4'b1111;
    #80;

    req = 4'b1010;
    #40;

    req = 4'b0000;
    #20;

    //--------------------------------------------------
    // Read Configuration Registers
    //--------------------------------------------------

    apb_read(8'h00);
    apb_read(8'h04);
    apb_read(8'h08);
    apb_read(8'h0C);

    apb_read(8'h10);
    apb_read(8'h14);

    //--------------------------------------------------
    // Read Performance Counters
    //--------------------------------------------------

    apb_read(8'h18);
    apb_read(8'h1C);
    apb_read(8'h20);

    apb_read(8'h24);
    apb_read(8'h28);
    apb_read(8'h2C);
    apb_read(8'h30);

    #30;

    $finish;

end

//--------------------------------------------------
// Monitor
//--------------------------------------------------
initial begin

$display("--------------------------------------------------------------");
$display(" Time    PSEL PENABLE PWRITE  PADDR     PRDATA      PREADY");
$display("--------------------------------------------------------------");

$monitor("%5t     %b      %b       %b    0x%02h   0x%08h    %b",
        $time,
        PSEL,
        PENABLE,
        PWRITE,
        PADDR,
        PRDATA,
        PREADY);

end

endmodule