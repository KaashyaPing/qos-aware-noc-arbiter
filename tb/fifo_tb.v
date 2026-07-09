`timescale 1ns/1ps

module fifo_tb;

reg clk;
reg reset;

reg write_en;
reg read_en;

reg [7:0] data_in;

wire [7:0] data_out;

wire empty;
wire full;

// Instantiate FIFO
fifo uut(
    .clk(clk),
    .reset(reset),
    .write_en(write_en),
    .read_en(read_en),
    .data_in(data_in),
    .data_out(data_out),
    .empty(empty),
    .full(full)
);

// Clock generation
always #5 clk = ~clk;

// Test sequence
initial begin

    clk = 0;
    reset = 1;
    write_en = 0;
    read_en = 0;
    data_in = 8'h00;

    //-----------------------------
    // Reset
    //-----------------------------
    #10;
    reset = 0;

    //-----------------------------
    // Write four values
    //-----------------------------
    write_en = 1;

    data_in = 8'h11;
    #10;

    data_in = 8'h22;
    #10;

    data_in = 8'h33;
    #10;

    data_in = 8'h44;
    #10;

    write_en = 0;

    //-----------------------------
    // Attempt write when full
    //-----------------------------
    write_en = 1;
    data_in = 8'h55;
    #10;
    write_en = 0;

    //-----------------------------
    // Read four values
    //-----------------------------
    read_en = 1;

    #10;
    #10;
    #10;
    #10;

    read_en = 0;

    //-----------------------------
    // Attempt read when empty
    //-----------------------------
    read_en = 1;
    #10;
    read_en = 0;

    //-----------------------------
    // Wrap-around test
    //-----------------------------
    write_en = 1;

    data_in = 8'hAA;
    #10;

    data_in = 8'hBB;
    #10;

    write_en = 0;

    //-----------------------------
    // Simultaneous Read & Write
    //-----------------------------
    write_en = 1;
    read_en  = 1;

    data_in = 8'hCC;
    #10;

    write_en = 0;
    read_en  = 0;

    //-----------------------------
    // Read remaining values
    //-----------------------------
    read_en = 1;

    #10;
    #10;

    read_en = 0;

    //-----------------------------
    // Finish
    //-----------------------------
    #20;
    $finish;

end

// Monitor
initial begin

$monitor(
"T=%0t WE=%b RE=%b Din=%h Dout=%h Count=%0d Empty=%b Full=%b WR=%0d RD=%0d",
$time,
write_en,
read_en,
data_in,
data_out,
uut.count,
empty,
full,
uut.wr_ptr,
uut.rd_ptr
);

end

endmodule