module arbiter(
    input clk,
    input reset,
    input [3:0] req,
    output reg [3:0] grant,

    // APB Interface
    input PSEL,
    input PENABLE,
    input PWRITE,
    input [7:0] PADDR,
    input [31:0] PWDATA,
    output reg [31:0] PRDATA,
    output reg PREADY
);

reg [1:0] pointer;
reg [1:0] next_pointer;
reg [3:0] age_counter [3:0];
integer i;
reg [3:0] age_limit_reg;
reg aged_request_found;
reg [1:0] aged_request;
reg high_pri_found;
reg [1:0] high_pri_request;
reg [3:0] same_pri_req;
reg [1:0] highest_priority;
reg [2:0] congestion_threshold_reg;
reg [2:0] active_requests;
reg congestion;
reg [1:0] congestion_level;
reg [31:0] total_requests;
reg [31:0] total_grants;
reg [31:0] starvation_events;
reg [31:0] qos_grants [3:0];
reg [1:0] priority_reg [3:0];



always @(posedge clk or posedge reset) begin
    if (reset) begin
        
        pointer <= 2'b00;
        
        total_requests    <= 0;
        total_grants      <= 0;
        starvation_events <= 0;

        qos_grants[0] <= 0;
        qos_grants[1] <= 0;
        qos_grants[2] <= 0;
        qos_grants[3] <= 0;

        

        age_limit_reg <= 4'd8;
        congestion_threshold_reg <= 3'd3;
    end
    else begin
        
        pointer <= next_pointer;

//--------------------------------------------------
// APB Counter Reset
//--------------------------------------------------
if (PSEL && PENABLE && PWRITE && PADDR == 8'h34)
begin
    total_requests    <= 0;
    total_grants      <= 0;
    starvation_events <= 0;

    qos_grants[0] <= 0;
    qos_grants[1] <= 0;
    qos_grants[2] <= 0;
    qos_grants[3] <= 0;
end

//--------------------------------------------------
// Normal Counter Updates
//--------------------------------------------------
else
begin
    total_requests <= total_requests + active_requests;

    if (grant != 4'b0000)
        total_grants <= total_grants + 1;

    if (aged_request_found)
        starvation_events <= starvation_events + 1;

    if (grant[0])
        qos_grants[0] <= qos_grants[0] + 1;

    if (grant[1])
        qos_grants[1] <= qos_grants[1] + 1;

    if (grant[2])
        qos_grants[2] <= qos_grants[2] + 1;

    if (grant[3])
        qos_grants[3] <= qos_grants[3] + 1;
end
        
       
    end
end

always @(*) begin
    grant = 4'b0000;
    next_pointer = pointer;
    active_requests = 0;
    congestion = 0;
    congestion_level = 2'b00;
    PREADY = 1'b1;

        // Count active requests
    if (req[0])
        active_requests = active_requests + 1;

    if (req[1])
        active_requests = active_requests + 1;

    if (req[2])
        active_requests = active_requests + 1;

    if (req[3])
        active_requests = active_requests + 1;

    // Check congestion
    if (active_requests >= congestion_threshold_reg)
        congestion = 1;
    
    // Determine congestion level
    if (active_requests <= 1)
        congestion_level = 2'b00;      // Low
    else if (active_requests <= 3)
        congestion_level = 2'b01;      // Medium
    else
        congestion_level = 2'b10;      // High


    // Grant to the aged request
    if(aged_request_found && req[aged_request])
    begin
        case(aged_request)

        2'd0:
        begin
            grant = 4'b0001;
            next_pointer = 2'd1;
        end

        2'd1:
        begin
            grant = 4'b0010;
            next_pointer = 2'd2;
        end

        2'd2:
        begin
            grant = 4'b0100;
            next_pointer = 2'd3;
        end

        2'd3:
        begin
            grant = 4'b1000;
            next_pointer = 2'd0;
        end

        endcase
    end

    else if (high_pri_found)
    begin
        

    case(pointer)

2'd0:
begin
    if(same_pri_req[0])
    begin
        grant = 4'b0001;
        next_pointer = 2'd1;
    end
    else if(same_pri_req[1])
    begin
        grant = 4'b0010;
        next_pointer = 2'd2;
    end
    else if(same_pri_req[2])
    begin
        grant = 4'b0100;
        next_pointer = 2'd3;
    end
    else if(same_pri_req[3])
    begin
        grant = 4'b1000;
        next_pointer = 2'd0;
    end
end
    

2'd1:
begin
    if(same_pri_req[1])
    begin
        grant = 4'b0010;
        next_pointer = 2'd2;
    end
    else if(same_pri_req[2])
    begin
        grant = 4'b0100;
        next_pointer = 2'd3;
    end
    else if(same_pri_req[3])
    begin
        grant = 4'b1000;
        next_pointer = 2'd0;
    end
    else if(same_pri_req[0])
    begin
        grant = 4'b0001;
        next_pointer = 2'd1;
    end
end

2'd2:
begin
    if(same_pri_req[2])
    begin
        grant = 4'b0100;
        next_pointer = 2'd3;
    end
    else if(same_pri_req[3])
    begin
        grant = 4'b1000;
        next_pointer = 2'd0;
    end
    else if(same_pri_req[0])
    begin
        grant = 4'b0001;
        next_pointer = 2'd1;
    end
    else if(same_pri_req[1])
    begin
        grant = 4'b0010;
        next_pointer = 2'd2;
    end
end

2'd3:
begin
    if(same_pri_req[3])
    begin
        grant = 4'b1000;
        next_pointer = 2'd0;
    end
    else if(same_pri_req[0])
    begin
        grant = 4'b0001;
        next_pointer = 2'd1;
    end
    else if(same_pri_req[1])
    begin
        grant = 4'b0010;
        next_pointer = 2'd2;
    end
    else if(same_pri_req[2])
    begin
        grant = 4'b0100;
        next_pointer = 2'd3;
    end
end

default:
begin
    grant = 4'b0000;
    next_pointer = 2'd0;
end

    endcase
    
end
end

always @(posedge clk or posedge reset)
begin
    if(reset)
    begin
        for(i=0; i<4; i=i+1)
            age_counter[i] <= 4'd0;
        
        priority_reg[0] <= 2'd3;
        priority_reg[1] <= 2'd2;
        priority_reg[2] <= 2'd1;
        priority_reg[3] <= 2'd0;
    end
    else
    begin
        for(i=0; i<4; i=i+1)
        begin
            if(req[i] && !grant[i])
                age_counter[i] <= age_counter[i] + 1'b1;

            else
                age_counter[i] <= 4'd0;
        end

        if (PSEL && PENABLE && PWRITE)
        begin
            case (PADDR)
            8'h00:
                priority_reg[0] <= PWDATA[1:0];

            8'h04:
                priority_reg[1] <= PWDATA[1:0];

            8'h08:
                priority_reg[2] <= PWDATA[1:0];

            8'h0C:
                priority_reg[3] <= PWDATA[1:0];

            8'h10:
                age_limit_reg <= PWDATA[3:0];

            8'h14:
                congestion_threshold_reg <= PWDATA[2:0];

            default:
            begin
            end
            endcase
        end
    end
end

always @(*) begin

    aged_request_found = 1'b0;
    aged_request = 2'd0;

    // Start with requester 0

    if(req[0] && age_counter[0] >= age_limit_reg)
    begin
        aged_request_found = 1'b1;
        aged_request = 2'd0;
    end

    // Compare requester 1

    if(req[1] &&
       age_counter[1] >= age_limit_reg &&
       (!aged_request_found ||
        age_counter[1] > age_counter[aged_request]))
    begin
        aged_request_found = 1'b1;
        aged_request = 2'd1;
    end

    // Compare requester 2

    if(req[2] &&
       age_counter[2] >= age_limit_reg &&
       (!aged_request_found ||
        age_counter[2] > age_counter[aged_request]))
    begin
        aged_request_found = 1'b1;
        aged_request = 2'd2;
    end

    // Compare requester 3

    if(req[3] &&
       age_counter[3] >= age_limit_reg &&
       (!aged_request_found ||
        age_counter[3] > age_counter[aged_request]))
    begin
        aged_request_found = 1'b1;
        aged_request = 2'd3;
    end

end

always @(*) begin

    high_pri_found = 1'b0;
    high_pri_request = 2'd0;
    highest_priority = 2'd0;

    // Check requester 0

    if(req[0])
    begin
        high_pri_found = 1'b1;
        high_pri_request = 2'd0;
        highest_priority = priority_reg[0];
    end

    // Compare requester 1

    if(req[1] &&
       (!high_pri_found ||
        priority_reg[1] > highest_priority))
    begin
        high_pri_found = 1'b1;
        high_pri_request = 2'd1;
        highest_priority = priority_reg[1];
    end

    // Compare requester 2

    if(req[2] &&
       (!high_pri_found ||
        priority_reg[2] > highest_priority))
    begin
        high_pri_found = 1'b1;
        high_pri_request = 2'd2;
        highest_priority = priority_reg[2];
    end

    // Compare requester 3

    if(req[3] &&
       (!high_pri_found ||
        priority_reg[3] > highest_priority))
    begin
        high_pri_found = 1'b1;
        high_pri_request = 2'd3;
        highest_priority = priority_reg[3];
    end

end

always @(*) begin

    same_pri_req = 4'b0000;

    if(req[0] && priority_reg[0] == highest_priority)
        same_pri_req[0] = 1'b1;

    if(req[1] && priority_reg[1] == highest_priority)
        same_pri_req[1] = 1'b1;

    if(req[2] && priority_reg[2] == highest_priority)
        same_pri_req[2] = 1'b1;

    if(req[3] && priority_reg[3] == highest_priority)
        same_pri_req[3] = 1'b1;

end
always @(*) begin
    PRDATA = 32'd0;

    if (PSEL && PENABLE && !PWRITE) begin
        case (PADDR)
8'h00:
    PRDATA = {30'd0, priority_reg[0]};

8'h04:
    PRDATA = {30'd0, priority_reg[1]};

8'h08:
    PRDATA = {30'd0, priority_reg[2]};

8'h0C:
    PRDATA = {30'd0, priority_reg[3]};

8'h10:
    PRDATA = {28'd0, age_limit_reg};

8'h14:
    PRDATA = {29'd0, congestion_threshold_reg};

8'h18:
    PRDATA = total_requests;

8'h1C:
    PRDATA = total_grants;

8'h20:
    PRDATA = starvation_events;

8'h24:
    PRDATA = qos_grants[0];

8'h28:
    PRDATA = qos_grants[1];

8'h2C:
    PRDATA = qos_grants[2];

8'h30:
    PRDATA = qos_grants[3];

default:
    PRDATA = 32'd0;
        endcase
    end
end

endmodule