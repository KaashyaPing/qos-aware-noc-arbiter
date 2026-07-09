module fifo(

    input clk,
    input reset,

    input write_en,
    input read_en,

    input [7:0] data_in,

    output reg [7:0] data_out,

    output empty,
    output full

);

    // FIFO Memory (Depth = 4, Width = 8)
    reg [7:0] mem [0:3];

    // Write and Read Pointers
    reg [1:0] wr_ptr;
    reg [1:0] rd_ptr;

    // Number of entries currently stored
    reg [2:0] count;

    // Status Flags
    assign empty = (count == 0);
    assign full  = (count == 4);

    always @(posedge clk)
    begin
        if (reset)
        begin
            wr_ptr   <= 2'd0;
            rd_ptr   <= 2'd0;
            count    <= 3'd0;
            data_out <= 8'd0;
        end
        else
        begin

            //--------------------------------------------------
            // Simultaneous Read and Write
            //--------------------------------------------------
            if (write_en && !full && read_en && !empty)
            begin
                // Write new data
                mem[wr_ptr] <= data_in;
                wr_ptr <= wr_ptr + 1;

                // Read oldest data
                data_out <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1;

                // Count remains unchanged
            end

            //--------------------------------------------------
            // Write Only
            //--------------------------------------------------
            else if (write_en && !full)
            begin
                mem[wr_ptr] <= data_in;
                wr_ptr <= wr_ptr + 1;
                count <= count + 1;
            end

            //--------------------------------------------------
            // Read Only
            //--------------------------------------------------
            else if (read_en && !empty)
            begin
                data_out <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1;
                count <= count - 1;
            end

        end
    end

endmodule