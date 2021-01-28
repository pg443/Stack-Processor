----------------------------------------------------------------------------------
-- Company: Drexel ece
-- Engineer: Prawat
-- Module Name:    bus_ip_mem_bridge - Behavioral 
-- Additional Comments: A bridge between bus or user ip to block ram memory
-- input signals are data and addresses from bus and ip to be muxed to mem
-- bus2mem_we,ip2mem_we are write enable from bus and ip
-- bus2mem_en is from bus controls the access to mem
-- output signals are to mem
-- busy signal is to ip indicating that bus is accessing memory
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity bus_ip_mem_bridge is
generic (A: natural := 10);
port(ip2mem_data_in,bus2mem_data_in : in  std_logic_vector(31 downto 0);
          ip2mem_addr,bus2mem_addr  : in  std_logic_vector(A-1 downto 0);
               bus2mem_we,ip2mem_we : in  std_logic_vector(0  downto 0);
                         bus2mem_en : in  std_logic;
	                          addra : out std_logic_vector(A-1 downto 0);
			                   dina : out std_logic_vector(31 downto 0);
					            wea : out std_logic_vector(0 downto 0);
			   			       busy : out std_logic);
end bus_ip_mem_bridge;

architecture Behavioral of bus_ip_mem_bridge is
begin
process(bus2mem_addr,bus2mem_data_in,
ip2mem_addr,ip2mem_data_in,bus2mem_we,ip2mem_we,
bus2mem_en)
begin
if bus2mem_en = '1' then 
    wea <= bus2mem_we;
    addra <= bus2mem_addr;
    dina <= bus2mem_data_in;
	 busy <= '1';
else
    wea <= ip2mem_we;
    addra <= ip2mem_addr;
    dina <= ip2mem_data_in;
	 busy <= '0';
end if;
end process;
end Behavioral;