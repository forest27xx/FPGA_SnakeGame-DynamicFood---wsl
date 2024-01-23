module state(
  input             pixel_clk,                  //VGA����ʱ��
  input             sys_rst_n,                //��λ�ź�
  input       [5:0]key,//������������
	input   wire flag,
	output	reg[2:0]		state_1,
	output	reg[1:0]		state_2
);	   

parameter one	= 2'b01;			//�Ѷ�Ϊ1
parameter two 	= 2'b10;			//�Ѷ�Ϊ2
parameter three = 2'b11;			//�Ѷ�Ϊ3

parameter face_start 	= 3'b001;	//��ʼ����Ŀ�ʼѡ��
parameter face_options 	= 3'b010;  //��ʼ���������ѡ��
parameter options		= 3'b011;  //�Ѷ����ý���
parameter game_start	= 3'b100;  //��Ϸ����Ŀ�ʼѡ��
parameter game_back		= 3'b101;  //��Ϸ����ķ���ѡ��
parameter game			= 3'b111;  //��Ϸ��
//state_1
always@(posedge pixel_clk or negedge sys_rst_n)
if(sys_rst_n==0)
	state_1<=game_start;
else     
  case(state_1)
    game_start:	if(key[4] ==1)//������Ϸ
          state_1<=game;
        else if(key[5] == 1)//�˳���Ϸ
          state_1<=game_back;
        else
          state_1<=game_start;
    game_back:	if(key[4] == 1)//���˵�
          state_1<=game_start;
			 else if(key[5] == 1)//������Ϸ
          state_1<=game;
        else
          state_1<=game_back;
    game:		if(key[4] == 1)//���˵�
          state_1<=game_start;
			 else if(key[5] == 1||flag==1)//�˳���Ϸ
          state_1<=game_back;
        else  
          state_1<=game;
  endcase
endmodule