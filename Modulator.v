module qpsk_modulator (
    input  logic clk,
    input  logic rst_n,                     //Active low reset
    input logic enable,                     //Enable modulation
    input  logic bit_in,            //Random bit coming in
    output reg  signed [15:0] I_out,
    output reg  signed [15:0] Q_out,
    output reg  signed [15:0] qpsk_wave
);

    logic ff1, ff2;

    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            ff1 <= 1'b0;
            ff2 <= 1'b0;
        end else if(enable)begin
            ff1 <= bit_in;
            ff2 <= ff1;
        end else begin
            ff1 <= ff1;
            ff2 <= ff2;
        end
    end

    // bit to symbol mapper
    logic [1:0] pair;
    
    assign pair = {ff2, ff1};

    // Bit Mapper 

    reg signed [7:0] I_sym, Q_sym;
    always_comb begin
        if(!rst_n)
            I_sym = 8'sd0;
            Q_sym = 8'sd0;
        else if()     
            case (bit_pair)
            2'b00: begin I_sym =  8'sd127; Q_sym =  8'sd127; end
            2'b01: begin I_sym = -8'sd127; Q_sym =  8'sd127; end
            2'b11: begin I_sym = -8'sd127; Q_sym = -8'sd127; end
            2'b10: begin I_sym =  8'sd127; Q_sym = -8'sd127; end
            default: begin I_sym = 0; Q_sym = 0; end
            endcase
    end

   
    // RC Filter 

    reg signed [7:0] I_d1, I_d2;
    reg signed [7:0] Q_d1, Q_d2;

    wire signed [15:0] I_filt = (I_sym + (I_d1 <<< 1) + I_d2) >>> 2;
    wire signed [15:0] Q_filt = (Q_sym + (Q_d1 <<< 1) + Q_d2) >>> 2;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            I_d1 <= 0; I_d2 <= 0;
            Q_d1 <= 0; Q_d2 <= 0;
            I_out <= 0; Q_out <= 0;
        end else begin
            I_d2 <= I_d1;
            I_d1 <= I_sym;
            Q_d2 <= Q_d1;
            Q_d1 <= Q_sym;
            I_out <= I_filt;
            Q_out <= Q_filt;
        end
    end
	 

    //Carrier Mixing

    reg [3:0] phase_cnt;
    localparam integer TABLE_SIZE = 16;

    reg signed [7:0] cos_table [0:15];
    reg signed [7:0] sin_table [0:15];

    initial begin
        cos_table[ 0]=127; cos_table[ 1]=118; cos_table[ 2]=90;  cos_table[ 3]=49;
        cos_table[ 4]=0;   cos_table[ 5]=-49; cos_table[ 6]=-90; cos_table[ 7]=-118;
        cos_table[ 8]=-127;cos_table[ 9]=-118;cos_table[10]=-90; cos_table[11]=-49;
        cos_table[12]=0;   cos_table[13]=49;  cos_table[14]=90;  cos_table[15]=118;

        sin_table[ 0]=0;   sin_table[ 1]=49;  sin_table[ 2]=90;  sin_table[ 3]=118;
        sin_table[ 4]=127; sin_table[ 5]=118; sin_table[ 6]=90;  sin_table[ 7]=49;
        sin_table[ 8]=0;   sin_table[ 9]=-49; sin_table[10]=-90; sin_table[11]=-118;
        sin_table[12]=-127;sin_table[13]=-118;sin_table[14]=-90; sin_table[15]=-49;
    end

    always @(posedge clk or posedge reset) begin
        if (reset)
            phase_cnt <= 0;
        else
            phase_cnt <= phase_cnt + 1;
    end

    // I*cos - Q*sin
    always @(posedge clk or posedge reset) begin
        if (reset)
            qpsk_wave <= 0;
        else
            qpsk_wave <= (I_out * cos_table[phase_cnt] - Q_out * sin_table[phase_cnt]) >>> 7;
    end

endmodule
