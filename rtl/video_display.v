//****************************************Copyright (c)***********************************//
//ԭ�Ӹ����߽�ѧƽ̨��www.yuanzige.com
//����֧�֣�www.openedv.com
//�Ա����̣�http://openedv.taobao.com
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡZYNQ & FPGA & STM32 & LINUX���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           rgb_display
// Last modified Date:  2020/05/28 20:28:08
// Last Version:        V1.0
// Descriptions:         vga�����ƶ���ʾģ��
//                      
//----------------------------------------------------------------------------------------
// Created by:          ����ԭ��
// Created date:        2020/05/28 20:28:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module  video_display(
    input             pixel_clk,                  //VGA����ʱ��
    input             sys_rst_n,                //��λ�ź�
    
    input      [10:0] pixel_xpos,               //���ص������
    input      [10:0] pixel_ypos,               //���ص�������   
    input       [5:0]key,//������������
    input	wire[2:0]	state_1,//�˵�״̬
    output reg [23:0] pixel_data                //���ص�����
    );    

//parameter define    
parameter  H_DISP  = 11'd1280;                  //�ֱ���--��
parameter  V_DISP  = 11'd720;                   //�ֱ���--��

localparam SIDE_W  = 11'd40;                    //��Ļ�߿���
localparam BLOCK_W = 11'd20;                    //������
localparam BLUE    = 24'b00000000_00000000_11111111;    //��Ļ�߿���ɫ ��ɫ
localparam WHITE   = 24'b11111111_11111111_11111111;    //������ɫ ��ɫ
localparam BLACK   = 24'b00000000_00000000_00000000;    //������ɫ ��ɫ
localparam RED    = 24'b11111111_00000000_00000000; // ��ɫ
localparam GREEN  = 24'b00000000_11111111_00000000; // ��ɫ
localparam Crimson = 24'hDC143C;
localparam FOOD_COLOR =Crimson ;
localparam INI_X =11'd640 ;//��ʼλ��
localparam INI_Y =11'd360 ;
localparam StandardF =30'd742500;
localparam speed =1 ;


//parameter define                  

localparam PIC_X_START = 11'd1;      //ͼƬ��ʼ�������

localparam PIC_Y_START = 11'd1;      //ͼƬ��ʼ��������

localparam PIC_WIDTH   = 11'd100;    //ͼƬ���

localparam PIC_HEIGHT  = 11'd100;    //ͼƬ�߶�


localparam FOOD_W =11'd20 ;//ʳ���С
localparam FOOD_X=11'd360 ;
localparam FOOD_Y=11'd460 ;
parameter game_start	= 3'b100;  //��Ϸ����Ŀ�ʼѡ��
parameter game_back		= 3'b101;  //��Ϸ����ķ���ѡ��
parameter game			= 3'b111;  //��Ϸ��
//reg define
reg   [13:0]  rom_addr  ;  //ROM��ַ
reg [10:0] block_x = INI_X ;                             //�������ϽǺ�����
reg [10:0] block_y = INI_Y ;                             //�������Ͻ�������
reg [3:0] SnakeSize=3;//�����߳���
localparam MaxSize =16 ;
reg [10:0] Snake_Array[MaxSize:0][1:0]; // �����ߵ�ÿ�ڵ���������
//food
reg [10:0]Food_Array[1:0];
reg FoodGene;
wire  [9:0]RandomX;
wire [9:0]RandomY;

reg [25:0] div_cnt;                             //ʱ�ӷ�Ƶ������
reg        h_direct;                            //����ˮƽ�ƶ�����1�����ƣ�0������
reg        v_direct;                            //������ֱ�ƶ�����1�����£�0��
reg [1:0]direction;
//wire define   

wire  [10:0]  x_cnt;       //�����������

wire  [10:0]  y_cnt;       //�����������

wire          rom_rd_en ;  //ROM��ʹ���ź�

wire  [23:0]  rom_rd_data ;//ROM����

wire move_en;                                   //�����ƶ�ʹ���źţ�Ƶ��Ϊ100hz
reg MOEN;                                       //�����ƶ�����
assign move_en = (div_cnt == StandardF*10/speed) ? 1'b1 : 1'b0;
assign  rom_rd_en = 1'b1;                  //��ʹ�����ߣ���һֱ��ROM����
//*****************************************************
//**                    main code
//*****************************************************

//rng_custom_range Ran1(pixel_clk,sys_rst_n,FoodGene,11'd100,11'd1000,RandomX);
//rng_custom_range Ran2(pixel_clk,sys_rst_n,FoodGene,11'd100,11'd600,RandomY);

always @(posedge pixel_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        MOEN=0;
    end
    else if (key[0] == 1) begin  // ��
        if(!(direction==2'd1))
            direction=2'd0;
            MOEN=1;
    end
    else if (key[1] == 1) begin  // ��
        if(!(direction==2'd0))
             direction=2'd1;
            MOEN=1;            
    end
    else if (key[2] == 1) begin  // ��
        if(!(direction==2'd3))
            direction=2'd2;
            MOEN=1;
    end
    else if (key[3] == 1) begin  // ��
        if(!(direction==2'd2))
            direction=2'd3;
            MOEN=1;
    end
    // ʡ�Կյ�else����
end

//ͨ����vga����ʱ�Ӽ�����ʵ��ʱ�ӷ�Ƶ
always @(posedge pixel_clk ) begin         
    if (!sys_rst_n)
        div_cnt <= 0;
    else begin
        if(div_cnt < StandardF*10/speed) 
            div_cnt <= div_cnt + 1'b1;
        else
            div_cnt <= 0;                   //������10ms������
    end
end
integer index0;
integer index1;
integer index2;
integer index3;
integer index4;
//���ݷ����ƶ����򣬸ı����ݺ�����
always @(posedge pixel_clk ) begin         
    if (!sys_rst_n) begin
        for(index0=0; index0<MaxSize; index0=index0+1) begin
            if(index0<SnakeSize)begin
            Snake_Array[index0][0] = INI_X - index0 * BLOCK_W;
            Snake_Array[index0][1] = INI_Y;
            end
        end
        Food_Array[0]=FOOD_X;
        Food_Array[1]=FOOD_Y;
    end
    else if (move_en&&MOEN) begin
        case (direction)
            2'd0:
            begin
                for(index1=MaxSize-1; index1>0; index1=index1-1) begin
                      if(index1<SnakeSize)begin
                    Snake_Array[index1][0] = Snake_Array[index1-1][0];
                    Snake_Array[index1][1] = Snake_Array[index1-1][1];
                      end
                end
                Snake_Array[0][1] = Snake_Array[0][1] -BLOCK_W;//����Ҫע���Ǽ�BLOCK_W,֮ǰ��Ϊ1���������غϳ�һ�������ˡ�����Ϊ�����ƶ���drawƵ�ʵ�����
            end
            2'b1:
            begin
                for(index2=MaxSize-1; index2>0; index2=index2-1) begin
                      if(index2<SnakeSize)begin
                    Snake_Array[index2][0] = Snake_Array[index2-1][0];
                    Snake_Array[index2][1] = Snake_Array[index2-1][1];
                      end
                end
                Snake_Array[0][1] = Snake_Array[0][1] + BLOCK_W;
            end
            2'd2:
            begin
                for(index3=MaxSize-1; index3>0; index3=index3-1) begin
                      if(index3<SnakeSize)begin
                    Snake_Array[index3][0] = Snake_Array[index3-1][0];
                    Snake_Array[index3][1] = Snake_Array[index3-1][1];
                      end
                end
                Snake_Array[0][0] = Snake_Array[0][0] -BLOCK_W; // ����Ϊx����
            end
            2'd3:
            begin
                for(index4=MaxSize-1; index4>0; index4=index4-1) begin
                      if(index4<SnakeSize)begin
                    Snake_Array[index4][0] = Snake_Array[index4-1][0]; // ������������
                    Snake_Array[index4][1] = Snake_Array[index4-1][1];
                      end
                end
                Snake_Array[0][0] = Snake_Array[0][0] + BLOCK_W; // ����Ϊx����
            end
        endcase
        //�Ե�ʳ��,ʳ������߼�        
		  if((Snake_Array[0][0]>=Food_Array[0])&&(Snake_Array[0][0]<Food_Array[0]+FOOD_W)&&(Snake_Array[0][1]>=Food_Array[1])&&(Snake_Array[0][1]<Food_Array[1]+FOOD_W))

        begin
            SnakeSize=SnakeSize+1;
				// �����µ�ʳ��λ��
            Food_Array[0]=100+(Snake_Array[0][0]*13+Snake_Array[1][0]*7+Snake_Array[2][0]*2)%(1200-100);
            Food_Array[1]=100+(Snake_Array[0][1]*13+Snake_Array[1][1]*7+Snake_Array[2][1]*2+Food_Array[0])%(600-100);
        end
    end
end


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//�ַ�����ѡ���Ѷȡ�
//�ַ�����ʾ��pixel_xpos[9:4] >=15 && pixel_xpos[9:4] < 25 && pixel_ypos[9:4] >= 8 && pixel_ypos[9:4] < 10��Χ�ڣ�
//�ڸ÷�Χ��char[char_y][159-char_x] == 1'b1�����ص㽫����ʾ�ɺ�ɫ
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

wire    [9:0]   char_x  ;   //�ַ���ʾX������
wire    [9:0]   char_y  ;   //�ַ���ʾY������

reg     [159:0] char    [31:0]  ;   //�ַ���160 ����32
 
assign  char_x  =   (pixel_xpos[9:4] >=40 && pixel_xpos[9:4] < 50 && pixel_ypos[9:4] >= 20 && pixel_ypos[9:4] < 22)? (pixel_xpos - 40*16) : 0;
assign  char_y  =   (pixel_xpos[9:4] >=40 && pixel_xpos[9:4] < 50 && pixel_ypos[9:4] >= 20 && pixel_ypos[9:4] < 22)? (pixel_ypos - 20*16) : 0;
 
//�ַ�����ѡ���Ѷȡ�
always@(posedge pixel_clk)
    begin
        char[0]     <=  160'h0000000000000000000000000000000000000000;
        char[1]     <=  160'h0000000000000000000000000000000000000000; 
        char[2]     <=  160'h00003c000000380001c000000000ee000003c000; 
        char[3]     <=  160'h0e003c000c063c0001e000f00000ff000003e000; 
        char[4]     <=  160'h0f003c180f07b80001cffff80000f7800001e038;
        char[5]     <=  160'h07803c3c0787b80001c7c0f00000f7800e00e07c; 
        char[6]     <=  160'h07bffffc078738c001c0c1e0003de3980ffffffe; 
        char[7]     <=  160'h079c3c60078f39e001c0e3c03fffe33c0f0e0700; 
        char[8]     <=  160'h07003cf0038ffff001de77c01c3dfffc0f0f0780; 
        char[9]     <=  160'h000ffff8030e38007fff7f800039c7000f0e0730; 
        char[10]     <=  160'h00073c00001c380039c03f00303bc7000f0e0778;
        char[11]     <=  160'h07003c18001c380001c03f00387bc7000ffffffc; 
        char[12]     <=  160'hff803c3c03b8383001c07fc01c7fc7300fce0700; 
        char[13]     <=  160'h77fffffe7ff0387801dffffe0e77c7780f0e0700; 
        char[14]     <=  160'h0738000077fffffc01ffdffe0f7ffffc0f0e0700; 
        char[15]     <=  160'h070600e007b9ce0001ff9e7807ffc7000f0e0700; 
        char[16]     <=  160'h0707fff00781ce0007fc1c3003fdc7000e0fff00; 
        char[17]     <=  160'h070700f00781ce003fc01c7801f9c7000e0e0700; 
        char[18]     <=  160'h070700e00781ce007fcffffc01e1c7000e0c0380; 
        char[19]     <=  160'h070700e00783ce187dc71c0003f1c7300e7fffc0; 
        char[20]     <=  160'h071fffe007838e1831c01c0003f1c7780e3e07c0; 
        char[21]     <=  160'h073f00e007878e1801c01c1807f9fffc0e070f80;
        char[22]     <=  160'h077700e007870e1801c01c3c0739c7001e078f00; 
        char[23]     <=  160'h07e7ffe0078f0e3c01dffffe0e3dc7001c03de00; 
        char[24]     <=  160'h07e700e00f9e0ffc01de1c001e3dc7001c01fc00; 
        char[25]     <=  160'h07c700e03ff80ffc01c01c003c19c7181c00f800; 
        char[26]     <=  160'h078700e07cf0000001c01c007819c73c3801fc00; 
        char[27]     <=  160'h070700e0f87fc0ff3fc01c00f001fffe3807ffc0; 
        char[28]     <=  160'h03070fe0701ffffe3fc01c00c001c000703f0ffe; 
        char[29]     <=  160'h000703e00007fff807c01c000001c00071fc03fe; 
        char[30]     <=  160'h000701c00000000003801c000001c000e7e00078; 
        char[31]     <=  160'h0000000000000000000000000000000000000000;
    end
 
integer index_draw;
reg found_match = 0; // ���һ����־��ָʾ�Ƿ��ҵ�ƥ��

// ����ͬ��������Ʋ�ͬ����ɫ
always @(posedge pixel_clk) begin
    if (!sys_rst_n) begin
        pixel_data <= BLACK; // Ĭ�Ϻ�ɫ����
    end else begin
      case (state_1)
            game_start: begin
              if(pixel_xpos[9:4] >=40 && pixel_xpos[9:4] < 50 && pixel_ypos[9:4] >= 20 && pixel_ypos[9:4] < 22&& char[char_y][159-char_x] == 1'b1) begin
						pixel_data<= BLACK; end//��ʾ����ѡ���Ѷȡ� �ַ�
						
					  else if(pixel_xpos[9:4] >=42 && pixel_xpos[9:4] < 43 && pixel_ypos[9:4] >= 40 && pixel_ypos[9:4] < 41) begin
						pixel_data<= GREEN;end//��ʾ�����ס����̷���
						
					  else if(pixel_xpos[9:4] >=44 && pixel_xpos[9:4] < 45 && pixel_ypos[9:4] >= 40 && pixel_ypos[9:4] < 41)begin
						pixel_data<= BLUE;end//��ʾ���еȡ��ĻƷ���
						
				   	else if(pixel_xpos[9:4] >=46 && pixel_xpos[9:4] < 47 && pixel_ypos[9:4] >= 40 && pixel_ypos[9:4] < 41)begin
						pixel_data<= RED;end//��ʾ�����ѡ��ĺ췽��
            else begin
                  pixel_data <= WHITE; // ����������ʾ������ɫ
              end 
            end
            game_back: begin
                    // ����ͼƬ
               if((pixel_xpos >= PIC_X_START) && (pixel_xpos < PIC_X_START + PIC_WIDTH)&& (pixel_ypos >= PIC_Y_START)&&(pixel_ypos < PIC_Y_START + PIC_HEIGHT))
                pixel_data <= rom_rd_data ;  //��ʾͼƬ
              else begin
                  pixel_data <= WHITE; // ����������ʾ������ɫ
              end
            end
            game: begin
              if ((pixel_xpos < SIDE_W) || (pixel_xpos >= H_DISP - SIDE_W)
                  || (pixel_ypos < SIDE_W) || (pixel_ypos >= V_DISP - SIDE_W)) begin
                  pixel_data <= BLUE; // ������Ļ�߿�Ϊ��ɫ
              end else begin
                //  
                  found_match = 0; // ��ÿ������ʱ�ӵı�Ե���ñ�־
                  for (index_draw = 0; index_draw < MaxSize && !found_match; index_draw = index_draw + 1) begin
                        if(index_draw<SnakeSize)begin
                      if (((pixel_xpos >= Snake_Array[index_draw][0]) && (pixel_xpos < Snake_Array[index_draw][0] + BLOCK_W))
                          && ((pixel_ypos >= Snake_Array[index_draw][1]) && (pixel_ypos < Snake_Array[index_draw][1] + BLOCK_W))) begin
                          pixel_data <= BLACK; // ���Ʒ���Ϊ��ɫ
                          found_match = 1; // ����ҵ�ƥ�䣬��ֹ��pixel_data����ΪWHITE
                      end
                          end
                  end
                  if (!found_match) begin
                      if((pixel_xpos>=Food_Array[0])&&(pixel_xpos<Food_Array[0]+FOOD_W)&&(pixel_ypos>=Food_Array[1])&&(pixel_ypos<Food_Array[1]+FOOD_W))
                          begin
                              pixel_data<=FOOD_COLOR;
                          end
                      else
                          pixel_data <= WHITE; // ���û���ҵ�ƥ�䣬����Ʊ���Ϊ��ɫ
                  end
              end
            end
            default: begin
                pixel_data <= BLACK; // Ĭ�ϱ���
            end
      endcase
    end
end

//���ݵ�ǰɨ���ĺ�������ΪROM��ַ��ֵ

always @(posedge pixel_clk)  begin
   if(!sys_rst_n)

         rom_addr <= 14'd0;

     //����������λ��ͼƬ��ʾ����ʱ���ۼ�ROM��ַ   

     else if((pixel_ypos >= PIC_Y_START) && (pixel_ypos < PIC_Y_START + PIC_HEIGHT)

         && (pixel_xpos >= PIC_X_START) && (pixel_xpos < PIC_X_START + PIC_WIDTH))

         rom_addr <= rom_addr + 1'b1;

     //����������λ��ͼƬ�������һ�����ص�ʱ��ROM��ַ����   

     else if((pixel_ypos >= PIC_Y_START + PIC_HEIGHT))

         rom_addr <= 14'd0;

 end


 //ROM���洢ͼƬ

 blk_mem_gen u_blk_mem_gen (

   .clka(pixel_clk), // input clka

   .ena(rom_rd_en), // input ena

   .wea(wea), // input [3 : 0] wea

   .addra(rom_addr), // input [31 : 0] addra

   .dina(dina), // input [31 : 0] dina

   .douta(rom_rd_data) // output [31 : 0] douta

 );

endmodule 
//gittest