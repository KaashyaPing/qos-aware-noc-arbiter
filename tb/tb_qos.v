`timescale 1ns/1ps

module tb_qos;

reg clk;
reg reset;
reg [3:0] req;
wire [3:0] grant;

// ---------------- APB Signals ----------------
reg        PSEL;
reg        PENABLE;
reg        PWRITE;
reg [7:0]  PADDR;
reg [31:0] PWDATA;
wire [31:0] PRDATA;
wire       PREADY;

// ---------------- DUT ----------------
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

// ---------------- Simulation ----------------
initial begin

    $dumpfile("qos.vcd");
    $dumpvars(0, tb_qos);

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

    //------------------------------------------------
    // Program QoS priorities
    //------------------------------------------------

    apb_write(8'h00, 32'd3);   // Master0 = Highest
    apb_write(8'h04, 32'd2);   // Master1
    apb_write(8'h08, 32'd1);   // Master2
    apb_write(8'h0C, 32'd0);   // Master3

    //------------------------------------------------
    // All masters request simultaneously
    //------------------------------------------------

    req = 4'b1111;

    repeat (10) begin
    @(posedge clk);
    $display("T=%0t Req=%b Grant=%b",
             $time,
             req,
             grant);
end

$monitor("T=%0t Req=%b Grant=%b P0=%0d P1=%0d P2=%0d P3=%0d",
         $time,
         req,
         grant,
         uut.priority_reg[0],
         uut.priority_reg[1],
         uut.priority_reg[2],
         uut.priority_reg[3]);

#100;

$finish;

    #100;

    $finish;

end

// ---------------- APB Write Task ----------------
task apb_write;

input [7:0] addr;
input [31:0] data;

begin

    @(posedge clk);

    PSEL    <= 1;
    PWRITE  <= 1;
    PENABLE <= 0;
    PADDR   <= addr;
    PWDATA  <= data;

    @(posedge clk);

    PENABLE <= 1;

    @(posedge clk);

    PSEL    <= 0;
    PENABLE <= 0;
    PWRITE  <= 0;

end

endtask

endmodule