//============================================================
//
//--- ALL RIGHTS RESERVED
//--- File		: async_fifo_16x16.v
//--- Auther	: smartbai
//--- Data		: 2020-09-17
//--- Version	: v1.0.0.0
//--- Abstract	: 
//
//------------------------------------------------------------
//Description	:
//------------------------------------------------------------
//--- Modification History:
//--- Date		By		Version		Change Description
//------------------------------------------------------------
//
//============================================================

module async_fifo_16x16 (
    // fifo write
    wr_clk,
    wr_en,
    almost_full,
    full,
    wr_data,
    // fifo_read
    rd_clk,
    rd_en,
    almost_empty,
    empty,
    rd_data,
    wr_reset,
    rd_reset
);
    //----------------------
    //parameter declaration
    //----------------------
    parameter ADDR_WIDTH = 4;
    parameter DATA_WIDTH = 16;
    parameter ALMOST_FULL_GAP = 3;  //离满还有ALMOST_FULL_GAP时，almost_full有效
    parameter ALMOST_EMPTY_GAP = 3;  //离满还有ALMOST_EMPTY_GAP时，almost_empty有效
    parameter FIFO_DEEP = 16;

    input wr_reset;                 //FIFO写时钟下的复位信号
    input wr_clk;                   //写时钟
    input wr_en;                    //写使能
    input [DATA_WIDTH-1:0] wr_data; //写数据
    output almost_full;             //将满信号
    output full;                    //满信号
    input rd_reset;                 //FIFO读时钟下的复位信号
    input rd_clk;                   //读时钟
    input rd_en;                    //读使能
    output almost_empty;            //将空信号
    output empty;                   //空信号
    output [DATA_WIDTH-1:0] rd_data;//读出数据
    //----------------------
    //wire declaration
    //----------------------
    wire [ADDR_WIDTH-1:0] wr_addr;  //FIFO写地址
    wire [ADDR_WIDTH-1:0] rd_addr;  //FIFO读地址
    wire [DATA_WIDTH-1:0] data_out_temp;//FIFO读出数据
    reg [ADDR_WIDTH:0] wr_gap;      //写指针与读指针之间的间隔
    reg [ADDR_WIDTH:0] rd_gap;      //读指针与写指针之间的间隔
    //----------------------
    //register declaration
    //----------------------
    wire [DATA_WIDTH-1:0] rd_data;  //fifo data output
    reg almost_full;                //fifo almost full
    reg full;                       //fifo full
    reg almost_empty;               //fifo almost empty
    reg empty;                      //fifo empty
    reg [ADDR_WIDTH:0] waddr;       //写地址，最高位为指针循环指示
    reg [ADDR_WIDTH:0] waddr_gray;  //写地址格雷码
    reg [ADDR_WIDTH:0] waddr_gray_sync_d1;//写地址格雷码，同步到读时钟
    reg [ADDR_WIDTH:0] waddr_gray_sync;
    reg [ADDR_WIDTH:0] raddr;       //读地址，最高位为指针循环指示
    reg [ADDR_WIDTH:0] raddr_gray;  //读地址格雷码
    reg [ADDR_WIDTH:0] raddr_gray_sync_d1;//读地址格雷码，同步到写时钟
    reg [ADDR_WIDTH:0] raddr_gray_sync;
    reg [ADDR_WIDTH:0] raddr_gray2bin;  //读地址的二进制码
    reg [ADDR_WIDTH:0] waddr_gray2bin;  //写地址的二进制码
    //----------------------
    //overview
    //*********
    //----------------------
    //asynchronous fifo read control logic
    //----------------------
    // RAM wire enable
    assign wen = wr_en && (!full);      //when fifo is full, writing to RAM is prohibited
    // fifo write address generated
    always @(posedge wr_clk or posedge wr_reset) begin
        if(wr_reset)
            waddr <= {(ADDR_WIDTH+1){1'b0}};
        else if(wen)
            waddr <= waddr + 1'b1;
        else
            waddr <= waddr;
    end
    assign wr_addr = waddr[ADDR_WIDTH-1:0]; //connect the write address to RAM
    //fifo write address: bin to gray
    always @(posedge wr_clk or posedge wr_reset) begin
        if(wr_reset)
            waddr_gray <= {(ADDR_WIDTH+1){1'b0}};
        else
            waddr_gray <= waddr ^ {1'b0, waddr[ADDR_WIDTH:1]};
    end

    //fifo read address gray sync to wr_clk
    //--synchronization by two level registers
    always @(posedge wr_clk or posedge wr_reset) begin
        if (wr_reset) begin
            raddr_gray_sync     <= {(ADDR_WIDTH+1){1'b0}};
            raddr_gray_sync_d1  <= {(ADDR_WIDTH+1){1'b0}};
        end
        else begin
            raddr_gray_sync     <= raddr_gray;
            raddr_gray_sync_d1  <= raddr_gray_sync;
        end
    end
    //read address gray code converted to binary code
    always @(*) begin
        integer i;
        raddr_gray2bin[ADDR_WIDTH-1] = raddr_gray_sync_d1[ADDR_WIDTH-1];
        for (i = ADDR_WIDTH-1; i>0; i=i-1)
            raddr_gray2bin[i-1] = raddr_gray2bin[i] ^ raddr_gray_sync_d1[i-1];
    end
    //interval calculation between write pointer and read point
    always @(*) begin
        if(raddr_gray2bin[ADDR_WIDTH] ^ waddr[ADDR_WIDTH])
            wr_gap = raddr_gray2bin[ADDR_WIDTH-1:0] - waddr[ADDR_WIDTH-1:0];
        else
            wr_gap = FIFO_DEEP + raddr_gray2bin - waddr;
    end
    //generate almost full signal
    always @(posedge wr_clk or posedge wr_reset) begin
        if (wr_reset) begin
            almost_full <= 1'b0;
        end
        else begin
            if (wr_gap < ALMOST_FULL_GAP) begin
                almost_full <= 1'b1;
            end
            else begin
                almost_full <= 1'b0;
            end
        end
    end
    //generate full signal
    always @(posedge wr_clk or posedge wr_reset) begin
        if (wr_reset) begin
            full <= 1'b0;
        end
        else begin
            full <= (!(|wr_gap)) || ((wr_gap == 1)&wr_en);
        end
    end
    //----------------------
    //asynchronous fifo read control logic
    //----------------------
    // RAM read enable
    assign ren = rd_en && (!empty); //when fifo is empty, reading from RAM is prohibited
    // fifo read address generated
    always @(posedge rd_clk or posedge rd_reset) begin
        if (rd_reset) begin
            raddr <= {(ADDR_WIDTH+1){1'b0}};
        end
        else if (ren) begin
            raddr <= raddr + 1'b1;
        end
    end
    assign rd_addr = raddr[ADDR_WIDTH-1:0]; //connect the read address to RAM
    //fifo read address: bin to gray
    always @(posedge rd_clk or posedge rd_reset) begin
        if (rd_reset) begin
            raddr_gray <= {(ADDR_WIDTH+1){1'b0}};
        end
        else
            raddr_gray <= raddr ^ {1'b0, raddr[ADDR_WIDTH:1]}
    end
    //fifo write address gray sync to rd_clk
    //--synchronization by two level registers
    always @(posedge rd_clk or posedge rd_reset) begin
        if (rd_reset) begin
            waddr_gray_sync <= {(ADDR_WIDTH+1){1'b0}};
            waddr_gray_sync_d1 <= {(ADDR_WIDTH+1){1'b0}};
        end
        else begin
            waddr_gray_sync <= waddr_gray;
            waddr_gray_sync_d1 <= waddr_gray_sync;
        end
    end
    //read address gray code converted to binary code
    always @(*) begin
        integer i;
        waddr_gray2bin[ADDR_WIDTH-1] = waddr_gray_sync_d1[ADDR_WIDTH-1];
        for (i = ADDR_WIDTH-1; i>0; i=i-1) begin
            waddr_gray2bin[i-1] = waddr_gray2bin[i] ^ waddr_gray_sync_d1[i-1];
        end
    end
    //interval calculation between read pointer and write point
    always @(*) begin
        rd_gap = waddr_gray2bin - raddr;
    end
    //generate almost empty signal
    always @(posedge rd_clk or posedge rd_reset) begin
        if(rd_reset)
            almost_empty <= 1'b0;
        else begin
            if(rd_gap <= ALMOST_EMPTY_GAP)
                almost_empty <= 1'b1;
            else
                almost_empty <= 1'b0;
        end
    end
    //generate empty signal
    always @(posedge rd_clk or posedge rd_reset) begin
        if(rd_reset)
            empty <= 1'b0;
        else
            empty <= (!(|rd_gap)) || ((rd_gap == 1)&rd_en);
    end
    //----------------------
    //例化FIFO内部RAM寄存器
    //----------------------
    ram_16x16 ram_16x16_u(
        //port a
        .clka(wr_clk),
        .addra(wr_addr),
        .dina(wr_data),
        .wra(wen),
        //port b
        .clkb(rd_clk),
        .addrb(rd_addr),
        .doutb(rd_data),
        .rdb(ren)
    );

endmodule