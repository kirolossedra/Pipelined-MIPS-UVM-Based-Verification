module Pipeline(input logic clk , input logic  rst );
// Pipeline stages
typedef enum bit [2:0] {
    IF_STAGE = 3'b000,
    ID_STAGE = 3'b001,
    EX_STAGE = 3'b010,
    MEM_STAGE =3'b011,
    WB_STAGE = 3'b100
} PIPELINE_STAGE;

// Pipeline registers
typedef struct {
    logic [31:0] pc;
    logic [31:0] instruction;
} IF_ID_REGISTER;

typedef struct {
    logic [1:0] alu_op ;
    logic [4:0] opcode;
    logic [4:0] rs;
    logic [4:0] rt;
    logic [4:0] rd;
    logic [4:0] write_reg;
    logic [4:0] shamt;
    logic [5:0] funct;
    logic [15:0] imm;
    logic [31:0] pc;
    logic [31:0] rs_data;
    logic [31:0] rt_data;
    logic [1:0] write_data_select;
    logic [31:0] alu_result;
} ID_EX_REGISTER;

typedef struct {
    logic [1:0] alu_op;
    logic [31:0] alu_a;
    logic [31:0] alu_b;
    logic [5:0] alu_shift;
    logic [31:0] alu_result;
    logic [31:0] pc;
    logic [31:0] rt_data;
    logic [31:0] mem_data;
    logic [4:0] write_reg;
    logic [1:0] write_data_select;
} EX_MEM_REGISTER;

typedef struct {
    logic [31:0] mem_data;
    logic [31:0] alu_result;
    logic [31:0] pc;
    logic [4:0] write_reg;
    logic [1:0] write_data_select;
} MEM_WB_REGISTER;




// Pipeline signals

logic [31:0] program_memory[0:1023];
logic [31:0] data_memory[0:1023];
logic [31:0] register_file[0:31];
logic [31:0] pc;
logic [31:0] next_pc;
logic [31:0] instruction;
logic [31:0] rs_data;
logic [31:0] rt_data;
logic [31:0] alu_a;
logic [31:0] alu_b;
logic [31:0] alu_result;
logic [31:0] mem_data;
logic [4:0] write_reg;
logic [1:0] write_data_select;
PIPELINE_STAGE stage;

// Pipeline registers
IF_ID_REGISTER if_id_reg;
ID_EX_REGISTER id_ex_reg;
EX_MEM_REGISTER ex_mem_reg;
MEM_WB_REGISTER mem_wb_reg;



// Instruction memory
initial begin
    // Load instructions into program memory
    
    $readmemh("imem.txt",program_memory );

end
// Data memory
initial begin
  $readmemh("dmem.txt",data_memory );
    // Initialize data memory
end

// Register file
initial begin
    // Initialize register file
    $readmemh("rf.txt",register_file );
end


initial begin 
  program_memory[0] = 32'h00022020;
program_memory[1]= 32'h00031020;
program_memory[2]= 32'h00421020;
register_file[0] = 0;
register_file[1] = 0;
register_file[2] = 0;
register_file[3] = 0;
register_file[4] = 0;
register_file[5] = 0;
register_file[6] = 0;
register_file[7] = 0;
register_file[8] = 0;
  
  
end


initial begin
  pc = 0;
  stage = IF_STAGE;
end

// Pipeline stages
always_ff @(posedge clk) begin
 
   pc <= pc+4;
   stage <= PIPELINE_STAGE'((stage +1) % 5);
   instruction <= program_memory[pc>>2];
  
  
///////////////////////////////////////////////////////
//
//         STAGE 1
//
////////// Instruction Fetch Stage ///////////////////
if (stage >= IF_STAGE) begin
   
  if_id_reg.instruction <= instruction;
 
  if_id_reg.pc <= pc+4;
  //stage = ID_STAGE;
    
end

  
/////////////////////////////////////////////////////// 
//  
//                STAGE   2
//  
///////// Instruction decode stage ////////////////////
if (stage >= ID_STAGE) begin
   // instruction <= program_memory[pc >> 2];
    id_ex_reg.opcode <= if_id_reg.instruction[31:26];
    id_ex_reg.rs <= if_id_reg.instruction[25:21];
    id_ex_reg.rt <= if_id_reg.instruction[20:16];
    id_ex_reg.write_reg <= if_id_reg.instruction[15:11];
    id_ex_reg.rd <= if_id_reg.instruction[15:11];
    id_ex_reg.shamt <= if_id_reg.instruction[10:6];
    id_ex_reg.funct <= if_id_reg.instruction[5:0];
    id_ex_reg.imm <= if_id_reg.instruction[15:0];
    id_ex_reg.rs_data <= register_file[id_ex_reg.rs];
    id_ex_reg.rt_data <= register_file[id_ex_reg.rt];
    id_ex_reg.write_data_select <= 1'b1;
    id_ex_reg.pc <= if_id_reg.pc;
    if (id_ex_reg.opcode == 6'b000000) begin
        id_ex_reg.alu_op <= 2'b00;
        if (id_ex_reg.funct == 6'b100000 || id_ex_reg.funct == 6'b100010 
            || id_ex_reg.funct == 6'b100100 || id_ex_reg.funct == 6'b100101
            || id_ex_reg.funct == 6'b101010) begin
            id_ex_reg.write_reg <= id_ex_reg.rd;
        end
    end else if (id_ex_reg.opcode == 6'b000010 
        || id_ex_reg.opcode == 6'b000011) begin
        id_ex_reg.alu_op <= 2'b01;
    end else begin
        id_ex_reg.alu_op <= 2'b10;
        id_ex_reg.write_reg <= id_ex_reg.rt;
    end
   // stage <= EX_STAGE;
end




//////////////////////////////////////////////////////////////////////
//
//               STAGE 3
//   
// Execute stage//////////////////////////////////////////////////////
if (stage >= EX_STAGE) begin
    if (id_ex_reg.alu_op == 2'b00) begin
        alu_a <= id_ex_reg.rs_data;
        if (id_ex_reg.imm[15] == 1) begin
            alu_b <= {{16{1'b1}}, id_ex_reg.imm};
        end else begin
            alu_b <= {{16{1'b0}}, id_ex_reg.imm};
        end
    end else if (id_ex_reg.alu_op == 2'b01) begin
        alu_a <= id_ex_reg.rs_data;
        alu_b <= id_ex_reg.imm;
    end else if (id_ex_reg.alu_op == 2'b10) begin
        alu_a <= id_ex_reg.rs_data;
        alu_b <= id_ex_reg.rt_data;
    end
    if (id_ex_reg.funct == 6'b001000) begin
        alu_b[5:0] <= id_ex_reg.rs;
    end
    if (id_ex_reg.funct == 6'b001001) begin
        alu_b[5:0] <= id_ex_reg.rt;
    end
    if (id_ex_reg.funct == 6'b000000) begin
        alu_b[5:0] <= id_ex_reg.shamt;
    end
    if (id_ex_reg.funct == 6'b000100) begin
        next_pc <= id_ex_reg.pc + {{26{instruction[31]}}, instruction[25:0], 2'b00};
    end else if (id_ex_reg.funct == 6'b000101) begin
        next_pc <= id_ex_reg.pc + {{26{instruction[31]}}, instruction[25:0], 2'b00};
    end else begin
        next_pc <= id_ex_reg.pc + 4;
    end
    if (id_ex_reg.alu_op == 2'b00) begin
        if (id_ex_reg.funct == 6'b100000) begin
            alu_result <= alu_a + alu_b;
        end else if (id_ex_reg.funct == 6'b100010) begin
            alu_result <= alu_a - alu_b;
        end else if (id_ex_reg.funct == 6'b100100) begin
            alu_result <= alu_a & alu_b;
        end else if (id_ex_reg.funct == 6'b100101) begin
            alu_result <= alu_a | alu_b;
        end else if (id_ex_reg.funct == 6'b101010) begin
            alu_result <= alu_a < alu_b ? 32'h00000001 : 32'h00000000;
        end
    end else if (id_ex_reg.alu_op == 2'b01) begin
        alu_result <= alu_a + alu_b;
    end else if (id_ex_reg.alu_op == 2'b10) begin
        if (id_ex_reg.opcode == 6'b100000&& id_ex_reg.funct == 6'b000000) begin
            alu_result <= alu_a * alu_b;
        end else begin
            alu_result <= alu_a + alu_b;
        end
    end
    ex_mem_reg.rt_data <= id_ex_reg.rt_data;
    ex_mem_reg.alu_result <= alu_result;
    ex_mem_reg.write_reg <= id_ex_reg.write_reg;
    ex_mem_reg.write_data_select <= id_ex_reg.write_data_select;
    ex_mem_reg.pc <= id_ex_reg.pc;
   // stage <= MEM_STAGE;
end
///////////////////////////////////////////////////////////////////////////////
//
//        STAGE 4
//
// Memory stage///////////////////////////////////////////////////////////////
    if (stage >= MEM_STAGE) begin
        if (id_ex_reg.alu_op == 2'b01) begin
            data_memory[id_ex_reg.alu_result] <= ex_mem_reg.rt_data;
    end
    mem_wb_reg.mem_data <= data_memory[ex_mem_reg.alu_result];
    mem_wb_reg.alu_result <= ex_mem_reg.alu_result;
    mem_wb_reg.write_reg <= ex_mem_reg.write_reg;
    mem_wb_reg.write_data_select <= ex_mem_reg.write_data_select;
    mem_wb_reg.pc <= ex_mem_reg.pc;
  //  stage <= WB_STAGE;
end
///////////////////////////////////////////////////////////////////////////////
//
//         STAGE 5
//
// Writeback stage/////////////////////////////////////////////////////////////
    if (stage == WB_STAGE) begin
        if (mem_wb_reg.write_data_select == 2'b00) begin
            register_file[mem_wb_reg.write_reg] <= mem_wb_reg.alu_result;
        end else begin
            register_file[mem_wb_reg.write_reg] <= mem_wb_reg.mem_data;
        end
      //  stage <= IF_STAGE;
    end
    
  



end

endmodule


module clock_Gen(clock);
    //i/o
    output reg clock;
    
    
    initial clock = 0;  //1)
    always #5 clock = ~clock; //2)

endmodule

module CPU_tb;
wire clock;

clock_Gen c1(clock);

Pipeline obj(clock,1);

endmodule




