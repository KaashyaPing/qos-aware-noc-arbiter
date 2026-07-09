module noc_top(

    input clk,
    input reset,

    input [3:0] write_en,

    input [7:0] data0,
    input [7:0] data1,
    input [7:0] data2,
    input [7:0] data3,

    output [3:0] grant

);