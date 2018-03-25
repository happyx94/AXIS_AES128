----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/21/2018 02:17:32 PM
-- Design Name: 
-- Module Name: aes128_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity aes128_tb is
--  Port ( );
end aes128_tb;

architecture Behavioral of aes128_tb is

	signal end_sim : boolean := false;
	constant period : time := 1us;
    component aes128cbc_v1_0 is  
        generic (
            AES_DATA_WIDTH    : integer    := 128
        );
        port (
            cipher_key : in std_logic_vector(AES_DATA_WIDTH-1 downto 0);
            -- Ports of Axi Slave Bus Interface S00_AXIS
            s00_axis_aclk    : in std_logic;
            s00_axis_aresetn    : in std_logic;
            s00_axis_tready    : out std_logic;
            s00_axis_tdata    : in std_logic_vector(AES_DATA_WIDTH-1 downto 0);
            s00_axis_tstrb    : in std_logic_vector((AES_DATA_WIDTH/8)-1 downto 0);
            s00_axis_tlast    : in std_logic;
            s00_axis_tvalid    : in std_logic;
    
            -- Ports of Axi Master Bus Interface M00_AXIS
            m00_axis_aclk    : in std_logic;
            m00_axis_aresetn    : in std_logic;
            m00_axis_tvalid    : out std_logic;
            m00_axis_tdata    : out std_logic_vector(AES_DATA_WIDTH-1 downto 0);
            m00_axis_tstrb    : out std_logic_vector((AES_DATA_WIDTH/8)-1 downto 0);
            m00_axis_tlast    : out std_logic;
            m00_axis_tready    : in std_logic
        );
    end component aes128cbc_v1_0;


signal rst_bar : std_logic;
signal clk : std_logic := '0';

signal cipher_key_tb : std_logic_vector(127 downto 0);

-- Axi Slave Bus Interface S00_AXIS
signal s00_axis_tready_tb   : std_logic;
signal s00_axis_tdata_tb    : std_logic_vector(127 downto 0);
signal s00_axis_tstrb_tb    : std_logic_vector((128/8)-1 downto 0);
signal s00_axis_tlast_tb    : std_logic;
signal s00_axis_tvalid_tb   : std_logic;
    
-- Axi Master Bus Interface M00_AXIS
signal m00_axis_tvalid_tb   : std_logic;
signal m00_axis_tdata_tb    : std_logic_vector(127 downto 0);
signal m00_axis_tstrb_tb    : std_logic_vector((128/8)-1 downto 0);
signal m00_axis_tlast_tb    : std_logic;
signal m00_axis_tready_tb   : std_logic;

begin
uut: aes128cbc_v1_0 port map (
            cipher_key => cipher_key_tb,
            -- Ports of Axi Slave Bus Interface S00_AXIS
            s00_axis_aclk => clk,
            s00_axis_aresetn => rst_bar,
            s00_axis_tready => s00_axis_tready_tb,
            s00_axis_tdata => s00_axis_tdata_tb,
            s00_axis_tstrb => s00_axis_tstrb_tb,
            s00_axis_tlast => s00_axis_tlast_tb,
            s00_axis_tvalid => s00_axis_tvalid_tb,
            
            -- Ports of Axi Master Bus Interface M00_AXIS
            m00_axis_aclk => clk,
            m00_axis_aresetn => rst_bar,
            m00_axis_tvalid => m00_axis_tvalid_tb,
            m00_axis_tdata => m00_axis_tdata_tb,
            m00_axis_tstrb => m00_axis_tstrb_tb,
            m00_axis_tlast => m00_axis_tlast_tb,
            m00_axis_tready => m00_axis_tready_tb
            );
            
stim: process
    begin
        rst_bar <= '0';
        m00_axis_tready_tb <= '0';
        wait for period;
        rst_bar <= '1';        
        cipher_key_tb <= x"5468617473206D79204B756E67204675"; --x"000102030405060708090a0b0c0d0e0f";
        wait for period;
        s00_axis_tlast_tb <= '0';
        s00_axis_tvalid_tb <= '1';
        s00_axis_tdata_tb <= x"54776F204F6E65204E696E652054776F"; -- x"00112233445566778899aabbccddeeff";
        if s00_axis_tready_tb = '0' then
            wait on s00_axis_tready_tb until s00_axis_tready_tb = '1';
        end if;
        wait until rising_edge(clk);
        s00_axis_tlast_tb <= '0';
        s00_axis_tvalid_tb <= '0';
        s00_axis_tdata_tb <= x"ccdd5533445566778899aabbccddeeff";
        wait on m00_axis_tvalid_tb until m00_axis_tvalid_tb = '1';
        m00_axis_tready_tb <= '1';
        s00_axis_tvalid_tb <= '1';
        s00_axis_tlast_tb <= '1';
        if s00_axis_tready_tb = '0' then
            wait on s00_axis_tready_tb until s00_axis_tready_tb = '1';
        end if;
        wait until rising_edge(clk);
        s00_axis_tvalid_tb <= '0';
        wait on m00_axis_tvalid_tb until m00_axis_tvalid_tb = '1';
        m00_axis_tready_tb <= '1';
        end_sim <= true;
        wait;
    end process;

sys_clk: process
	begin
		wait for period/2;
		loop
			clk <= not clk;
			wait for period/2;
			exit when end_sim = true;
		end loop;
		wait;
	end process;

end Behavioral;
