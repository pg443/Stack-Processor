----------------------------------------------------------------------------------
-- Company: Drexel ECE
-- Engineer: Prawat
-- Module Name:    sp - Behavioral 
-- Additional Comments: Stack Processor
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity splite is
generic (A : natural := 10);
port (
run,reset,bus2mem_en,bus2mem_we,ck : in  std_logic;
                      bus2mem_addr : in  std_logic_vector(A-1 downto 0);
                   bus2mem_data_in : in  std_logic_vector(31 downto 0);
                   sp2bus_data_out : out std_logic_vector(31 downto 0);
				              done : out std_logic);
end splite;

architecture Behavioral of splite is

-- bram signals
-- wea is bram port we is processor signal 
signal wea, we : STD_LOGIC_VECTOR(0 DOWNTO 0);  
signal addra   : STD_LOGIC_VECTOR(A-1 DOWNTO 0);  
signal dina    : STD_LOGIC_VECTOR(31 DOWNTO 0);
signal douta   : STD_LOGIC_VECTOR(31 DOWNTO 0);
--cast bus2mem_we to std_logic_vector
signal temp_we   : STD_LOGIC_VECTOR(0 DOWNTO 0);

-------------------------
-- processor registers
-------------------------

-- pointers
signal sp,pc,mem_addr : std_logic_vector(A-1 downto 0);

-- data registers
signal mem_data_in,mem_data_out,ir : std_logic_vector(31 downto 0);
signal temp1,temp2 : std_logic_vector(31 downto 0);

-- flags
signal busy, done_FF: std_logic;
signal less_than_flag, grtr_than_flag, eq_flag: std_logic;
------------------
-- machine state
------------------
type state is (idle,fetch,fetch2,fetch4,fetch5,exe,chill);--fetch3,
signal n_s: state;

-----------------------------------
-- Instruction Definitions
-- Leftmost hex is the step in an instruction
-- higher hex is the code for an instruction,
-- e.g., the steps in SC (constant) instruction 0x01,.., 0x05
-- the steps in sl (load from memory) 0x11 to 0x19
-- When shoter Latency BRAM states are eliminated
-----------------------------------

constant HALT : std_logic_vector(31 downto 0) := (x"000000FF");

constant SC   : std_logic_vector(31 downto 0) := (x"00000001");
constant SC2  : std_logic_vector(31 downto 0) := (x"00000002");
--constant SC3  : std_logic_vector(31 downto 0) := (x"00000003");
constant SC4  : std_logic_vector(31 downto 0) := (x"00000004");
constant SC5  : std_logic_vector(31 downto 0) := (x"00000005");

 constant sl   : std_logic_vector(31 downto 0) := (x"00000011");
 constant sl2  : std_logic_vector(31 downto 0) := (x"00000012");
-- constant sl3  : std_logic_vector(31 downto 0) := (x"00000013");
 constant sl4  : std_logic_vector(31 downto 0) := (x"00000014");
 constant sl5  : std_logic_vector(31 downto 0) := (x"00000015");
 constant sl6  : std_logic_vector(31 downto 0) := (x"00000016");
-- constant sl7  : std_logic_vector(31 downto 0) := (x"00000017");
 constant sl8  : std_logic_vector(31 downto 0) := (x"00000018");
 constant sl9  : std_logic_vector(31 downto 0) := (x"00000019");
 
 constant ss   : std_logic_vector(31 downto 0) := (x"00000021");
 constant ss2  : std_logic_vector(31 downto 0) := (x"00000022");
-- constant ss3  : std_logic_vector(31 downto 0) := (x"00000023");
 constant ss4  : std_logic_vector(31 downto 0) := (x"00000024");
 constant ss5  : std_logic_vector(31 downto 0) := (x"00000025");
 constant ss6  : std_logic_vector(31 downto 0) := (x"00000026");

 constant sadd : std_logic_vector(31 downto 0) := (x"00000031");
 constant sadd2: std_logic_vector(31 downto 0) := (x"00000032");
-- constant sadd3: std_logic_vector(31 downto 0) := (x"00000033");
 constant sadd4: std_logic_vector(31 downto 0) := (x"00000034");
 constant sadd5: std_logic_vector(31 downto 0) := (x"00000035");
 constant sadd6: std_logic_vector(31 downto 0) := (x"00000036");
 
 constant ssub : std_logic_vector(31 downto 0) := (x"00000041");
 constant ssub2: std_logic_vector(31 downto 0) := (x"00000042");
-- constant ssub3: std_logic_vector(31 downto 0) := (x"00000043");
 constant ssub4: std_logic_vector(31 downto 0) := (x"00000044");
 constant ssub5: std_logic_vector(31 downto 0) := (x"00000045");
 constant ssub6: std_logic_vector(31 downto 0) := (x"00000046"); 

 constant sjlt : std_logic_vector(31 downto 0) := (x"00000051");
 constant sjlt2: std_logic_vector(31 downto 0) := (x"00000052");
-- constant sjlt3: std_logic_vector(31 downto 0) := (x"00000053");
 constant sjlt4: std_logic_vector(31 downto 0) := (x"00000054");
 constant sjlt5: std_logic_vector(31 downto 0) := (x"00000055"); 
 
 constant sjgt : std_logic_vector(31 downto 0) := (x"00000061");
 constant sjgt2: std_logic_vector(31 downto 0) := (x"00000062");
-- constant sjgt3: std_logic_vector(31 downto 0) := (x"00000063");
 constant sjgt4: std_logic_vector(31 downto 0) := (x"00000064");
 constant sjgt5: std_logic_vector(31 downto 0) := (x"00000065"); 
 
 constant sjeq : std_logic_vector(31 downto 0) := (x"00000071");
 constant sjeq2: std_logic_vector(31 downto 0) := (x"00000072");
-- constant sjeq3: std_logic_vector(31 downto 0) := (x"00000073");
 constant sjeq4: std_logic_vector(31 downto 0) := (x"00000074");
 constant sjeq5: std_logic_vector(31 downto 0) := (x"00000075");
 
 constant sjmp : std_logic_vector(31 downto 0) := (x"000000E1");
 constant sjmp2: std_logic_vector(31 downto 0) := (x"000000E2");
-- constant sjmp3: std_logic_vector(31 downto 0) := (x"000000E3");
 constant sjmp4: std_logic_vector(31 downto 0) := (x"000000E4");
 constant sjmp5: std_logic_vector(31 downto 0) := (x"000000E5");

 constant scmp : std_logic_vector(31 downto 0) := (x"000000F1");
 constant scmp2: std_logic_vector(31 downto 0) := (x"000000F2");
-- constant scmp3: std_logic_vector(31 downto 0) := (x"000000F3");
 constant scmp4: std_logic_vector(31 downto 0) := (x"000000F4");
 constant scmp5: std_logic_vector(31 downto 0) := (x"000000F5");
 constant scmp6: std_logic_vector(31 downto 0) := (x"000000F6");

 constant smul : std_logic_vector(31 downto 0) := (x"00000101");
 constant smul2: std_logic_vector(31 downto 0) := (x"00000102");
-- constant smul3: std_logic_vector(31 downto 0) := (x"00000103");
 constant smul4: std_logic_vector(31 downto 0) := (x"00000104");
 constant smul5: std_logic_vector(31 downto 0) := (x"00000105");
 constant smul6: std_logic_vector(31 downto 0) := (x"00000106");
 
------------------
-- components 
------------------
COMPONENT bram1032
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END COMPONENT;
-- MEM bridge multiplexes BUS or processor signals to bram.
-- It also flags busy signal.
component  bus_ip_mem_bridge
generic(A: natural := 10); -- A-bit Address
port(
ip2mem_data_in,bus2mem_data_in : in  std_logic_vector(31 downto 0);
     ip2mem_addr,bus2mem_addr  : in  std_logic_vector(A-1 downto 0);
          bus2mem_we,ip2mem_we : in  std_logic_vector(0  downto 0);
                    bus2mem_en : in  std_logic;
	                     addra : out std_logic_vector(A-1 downto 0);
			              dina : out std_logic_vector(31 downto 0);
                           wea : out std_logic_vector(0 downto 0);
                          busy : out std_logic);
end component;

begin

---------------------------
-- components instantiation
---------------------------

temp_we(0) <= bus2mem_we; -- wire bus2mem_we to an std_logic_vector

-- MEM bridge multiplexes BUS or processor signals to bram.
bridge: bus_ip_mem_bridge -- It also flags busy signal to processor.
generic map(A)
port map(bus2mem_addr => bus2mem_addr, 
      bus2mem_data_in => bus2mem_data_in,
          ip2mem_addr => mem_addr, 
       ip2mem_data_in => mem_data_in,
           bus2mem_we => temp_we,
            ip2mem_we => we,
           bus2mem_en => bus2mem_en,
                addra => addra, 
                 dina => dina, 
                  wea => wea,
                 busy => busy);

-- main memory
mm : bram1032 PORT MAP (clka => ck,
                         wea => wea,
                       addra => addra,
                        dina => dina,
                       douta => douta);

-- memory data out register always get new douta
process(ck)
begin
if ck='1' and ck'event then
  if reset = '1' then mem_data_out <= (others => '0'); 
  else mem_data_out <= douta;
  end if;
end if;
end process;

 -- wire to output ports sp2bus_data_out
sp2bus_data_out <= mem_data_out; done <= done_FF;

-------------------
-- Stack Processor
-------------------

process(ck)
-- temp signal for multiply instruction
variable temp_mult:std_logic_vector(63 downto 0);
begin
if ck='1' and ck'event then
  if reset='1' then n_s <= idle; else
                 --           Machine State Diagram
  case n_s is    --              run               halt
    when chill =>--reset~~>(idle)-->(fetch)-->(exe)-->(chill)
	   null;     --                    |        |
                 --                    |        v
                 --                     <----(case ir)
    when idle =>
	   pc <= (others => '0');
	   sp <= (7 => '1', others => '0'); -- stack base 128
           ir <= (others => '0');
        temp1 <= (others => '0'); temp2 <= (others => '0');
     mem_addr <= (others => '0'); 
  mem_data_in <= (others => '0');
           we <= "0"; done_FF <= '0';

      -- poll on run and not busy 
	  if run='1' and busy='0' then n_s <= fetch; end if;

    when fetch => -- "init" means to initiate an action
	 mem_addr <= pc; pc <= pc+1;--init load pc to mem_addr 
           we <= "0"; -- enable read next state
		  n_s <= fetch2;
      when fetch2 => -- mem_addr valid, pc advanced
		      we <= "0";     -- read         -----
             n_s <= fetch4;                  ----- mem_addr
--    when fetch3 => -- mem read latency=1     |   register
--            we <= "0"; -- read            --------
--            n_s <= fetch4;--             |  BRAM  |
      when fetch4 => -- douta valid         --------
              we <= "0"; -- read               | dout
             n_s <= fetch5; --               ----- 
      when fetch5 => -- mem_data_out valid   ----- mem_data_out
              we <= "0"; -- read               |   register
	          ir <= mem_data_out;-- init ir load 
             n_s <= exe;

     when exe =>   -- ir loaded
       case ir is -- Machine Instructions

	   when halt => -- signal done output and go to chill
          done_FF <= '1'; n_s <= chill;

       -- Stack Constant, init load constant pointed to by pc
	   when sc => 
        mem_addr <= pc;  --pc points at constant 
              pc <= pc+1;--advance to next instruction
              we <= "0"; --enable read next state
              ir <= sc2;
         when sc2 => -- mem_addr valid
		      we <= "0"; -- read
		      ir <= sc4;
--       when sc3 => -- douta not valid latency 1
--		      we <= "0"; -- read
--		      ir <= sc4;
         when sc4 => -- douta valid
              we <= "0"; -- read
              ir <= sc5;  			
         when sc5 => -- mem_data_out valid
        mem_addr <= sp; sp <= sp+1;
     mem_data_in <= mem_data_out;
              we <= "1"; -- write enable next state
             n_s <= fetch;

        --Load data from memory:pop address,read and stack data
	   when sl => 
        mem_addr <= sp-1; sp <= sp-1;--init pop data address
              we <= "0"; -- enable read next state
              ir <= sl2;
         when sl2 => -- mem_addr updated
		      we <= "0"; -- read
		      ir <= sl4;
--       when sl3 => -- douta not valid latency 1
--            we <= "0"; -- read
--            ir <= sl4; 		
         when sl4 => -- douta valid
		      we <= "0"; -- read
		      ir <= sl5; 	
         when sl5 => -- mem_data_out valid
	    mem_addr <= mem_data_out(A-1 downto 0);--data Address
		      we <= "0"; -- read
              ir <= sl6;
         when sl6 => -- mem_addr updated
		      we <= "0"; -- read
		      ir <= sl8; 
--       when sl7 => -- douta not valid latency 1
--            we <= "0"; -- read
--            ir <= sl8;        			
         when sl8 => -- douta valid
		      we <= "0"; -- read
              ir <= sl9; 	 	
         when sl9 => -- mem_data_out valid
        mem_addr <= sp; sp <= sp+1;
     mem_data_in <= mem_data_out;--data read
              we <= "1"; -- write enable in next state
             n_s <= fetch;

       --Store data to memory:pop data,address,write to memory
       when ss =>
        mem_addr <= sp-1; sp <= sp-1;--init1 pop data
	          we <= "0"; -- read
              ir <= ss2;
         when ss2 =>  -- mem_addr updated1
        mem_addr <= sp-1; sp <= sp-1;--init2 pop address
              we <= "0"; -- read
              ir <= ss4;
--       when ss3 =>      --douta1 not valid latency 1,
--            we <= "0"; -- mem_addr updated2
--            ir <= ss4;			
         when ss4 =>      -- douta valid1, 
              we <= "0"; --douta2 not valid latency 1
              ir <= ss5; 	 	
         when ss5 =>  --douta valid2, mem_data_out valid1
              we <= "0"; -- read
           temp1 <= mem_data_out;--temp <= data
              ir <= ss6;
         when ss6 =>  -- mem_data_out valid2
        mem_addr <= mem_data_out(A-1 downto 0);--init write
     mem_data_in <= temp1; --data in temp1
              we <= "1"; -- write enable in next state
             n_s <= fetch;
       
       -- Add - pop operands add and push
       when sadd =>
          mem_addr <= sp-1;sp <= sp-1;--init1 pop operand1
                we <= "0"; -- read
                ir <= sadd2;
         when sadd2 => -- mem_addr updated1
	      mem_addr <= sp-1; sp <= sp-1;--init2 pop operand2
		        we <= "0"; -- read
		        ir <= sadd4;
--       when sadd3 =>--douta1 not valid latency 1,mem_addr updated2
--              we <= "0"; -- read
--              ir <= sadd4;
         when sadd4 =>  -- douta valid1, douta2 not valid
                we <= "0"; -- read
                ir <= sadd5; 	 	
         when sadd5 =>  -- douta valid2, mem_data_out valid1
                we <= "0"; -- read
             temp1 <= mem_data_out;--temp1 <= operand1
                ir <= sadd6;
         when sadd6 => -- mem_data_out valid2
          mem_addr <= sp; sp <= sp+1; -- init push
        mem_data_in <= temp1+mem_data_out;--operand1+operand2
                we <= "1";  -- write enable in next state
               n_s <= fetch;

       -- Substract - pop operands, subtract and push, and set flags
	   when ssub => 
         mem_addr <= sp-1; sp <= sp-1;--init pop operand1
               we <= "0"; -- read
               ir <= ssub2;
         when ssub2 => -- mem_addr updated1
          mem_addr <= sp-1; sp <= sp-1;--init pop operand2
                we <= "0"; -- read
                ir <= ssub4;
--       when ssub3 => -- douta1 not valid latency 1, mem_addr updated2
--              we <= "0"; -- read
--              ir <= ssub4;            
         when ssub4 => -- douta1 valid1, douta2 not valid
                we <= "0"; -- mem_addr updated2
                ir <= ssub5;          
         when ssub5 =>  -- douta valid2, mem_data_out valid1
                we <= "0"; -- read
             temp1 <= mem_data_out;--temp1 <= operand1
                ir <= ssub6;
         when ssub6 => -- mem_data_out valid2
          mem_addr <= sp; sp <= sp+1; -- init push
       mem_data_in <= temp1-mem_data_out;--operand1-operand2
                we <= "1";  -- write enable in next state
  if mem_data_out<temp1 then less_than_flag<='1';else less_than_flag<='0';end if;
  if mem_data_out>temp1 then grtr_than_flag<='1';else grtr_than_flag<='0';end if;
  if mem_data_out=temp1 then        eq_flag<='1';else        eq_flag<='0';end if;
               n_s <= fetch;

       -- Multiply - pop operands multiply and push
	   when smul =>
			 mem_addr <= sp-1; sp <= sp-1;--init1 pop operand1
			 we <= "0"; -- read
			 ir <= smul2;
         when smul2 => -- mem_addr updated1
		  mem_addr <= sp-1; sp <= sp-1;--init2 pop operand2
	            we <= "0"; -- read
	            ir <= smul4;
--       when smul3 => -- douta1 not valid latency 1, mem_addr updated2
--              we <= "0"; -- read
--              ir <= smul4;			
         when smul4 =>  -- douta valid1, douta2 not valid
	            we <= "0"; -- read
	            ir <= smul5; 	 	
		 when smul5 =>  -- douta valid2, mem_data_out valid1
		        we <= "0"; -- read
			 temp1 <= mem_data_out;--temp1 <= operand1
			    ir <= smul6;
		 when smul6 => -- mem_data_out valid2
          mem_addr <= sp; sp <= sp+1; -- init push
         temp_mult := temp1*mem_data_out;
	   mem_data_in <= temp_mult(31 downto 0);--operand1*operand2
			 temp2 <= temp_mult(63 downto 32);--High 32bits assigned for sanity check
                we <= "1";  -- write enable in next state
               n_s <= fetch;
               
       -- Compare - pop operands, subtract and set flags 
       when scmp =>
          mem_addr <= sp-1; sp <= sp-1;--init pop operand1
                we <= "0"; -- read
                ir <= scmp2;
         when scmp2 => -- mem_addr updated1
          mem_addr <= sp-1; sp <= sp-1;--init pop operand2
                we <= "0"; -- read
                ir <= scmp4;
--       when scmp3 => -- douta1 not valid latency 1, mem_addr updated2
--              we <= "0"; -- read
--              ir <= scmp4;        
         when scmp4 =>  -- douta valid1, douta2 not valid
                we <= "0"; -- read
                ir <= scmp5;          
         when scmp5 =>  --  douta valid2, mem_data_out valid1
                we <= "0"; -- read
             temp1 <= mem_data_out;--temp1 <= operand1
              ir <= scmp6;
         when scmp6 => -- mem_data_out valid2
  if mem_data_out<temp1 then less_than_flag<='1';else less_than_flag<='0';end if;
  if mem_data_out>temp1 then grtr_than_flag<='1';else grtr_than_flag<='0';end if;
  if mem_data_out=temp1 then        eq_flag<='1';else        eq_flag<='0';end if;
              n_s <= fetch;

       -- Jump - pop address, pc <= address
	   when sjmp => 
	      mem_addr <= sp-1; sp <= sp-1;-- init pop jump-to address
	            we <= "0"; -- read
                ir <= sjmp2;
         when sjmp2 => -- mem_addr updated
		        we <= "0"; -- read
		        ir <= sjmp4;
--       when sjmp3 => -- douta not valid latency 1
--              we <= "0"; -- read
--              ir <= sjmp4;			
         when sjmp4 =>  -- douta valid
		        we <= "0"; -- read
		        ir <= sjmp5; 	 	
		 when sjmp5 =>  -- mem_data_out valid
		        we <= "0"; -- read
			    pc <= mem_data_out(A-1 downto 0);
		       n_s <= fetch;

    -- Jump Less Than -pop address,pc<=address on less_than_flag
	   when sjlt => 
	     mem_addr <= sp-1; sp <= sp-1;-- init pop jump-to address
			    we <= "0"; -- read
			    ir <= sjlt2;
         when sjlt2 => -- mem_addr updated
		        we <= "0"; -- read
		        ir <= sjlt4;
--         when sjlt3 => -- douta not valid latency 1
--            we <= "0"; -- read
--            ir <= sjlt4;
         when sjlt4 =>  -- douta valid
		        we <= "0"; -- read
		        ir <= sjlt5; 	 	
		 when sjlt5 =>  -- mem_data_out valid
		        we <= "0"; -- read
   if less_than_flag='1' then pc<=mem_data_out(A-1 downto 0);end if;
			   n_s <= fetch;
			   
    -- Jump greater Than -pop address,pc<=address on grtr_than_flag
       when sjgt =>
          mem_addr <= sp-1; sp <= sp-1;-- init pop jump-to address
                we <= "0"; -- read
                ir <= sjgt2;
         when sjgt2 => -- mem_addr updated
                we <= "0"; -- read
                ir <= sjgt4;
--       when sjgt3 => -- douta not valid latency 1
--              we <= "0"; -- read
--              ir <= sjgt4;
         when sjgt4 =>  -- douta valid
                we <= "0"; -- read
                ir <= sjgt5;          
         when sjgt5 =>  -- mem_data_out valid
                we <= "0"; -- read
   if grtr_than_flag='1' then pc<=mem_data_out(A-1 downto 0);end if;
               n_s <= fetch;
               
    -- Jump Equal - pop address, pc <= address on eq_flag
	   when sjeq => 
                     mem_addr <= sp-1; sp <= sp-1;-- init pop jump-to address
                     we <= "0"; -- read
                     ir <= sjeq2;
         when sjeq2 => -- mem_addr updated
                we <= "0"; -- read
                ir <= sjeq4;
--       when sjeq3 => -- douta not valid latency 1
--              we <= "0"; -- read
--              ir <= sjeq4;
         when sjeq4 =>  -- douta valid
                we <= "0"; -- read
                ir <= sjeq5;          
         when sjeq5 =>  -- mem_data_out valid
                we <= "0"; -- read
          if eq_flag='1' then pc<=mem_data_out(A-1 downto 0);end if;
               n_s <= fetch;

       when others =>null;
      end case; -- instructions
     end case;  -- fetch-execute
  end if;       -- reset fence
end if;         -- clock fence
end process;
end Behavioral;
