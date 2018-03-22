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
use IEEE.numeric_std.all;

library work;
use work.aes128Pkg.all;
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

    component aes128 is  
    port (
    Clk_CI : in std_logic;
    Reset_RBI : in std_logic;
    Start_SI : in std_logic;
    NewCipherkey_SI : in std_logic;
    Busy_SO : out std_logic;
    Plaintext_DI  : in  std_logic_vector(127 downto 0);
    Cipherkey_DI  : in  std_logic_vector(127 downto 0);
    Ciphertext_DO : out std_logic_vector(127 downto 0));
    end component aes128;

    signal clk : std_logic := '0';
    signal Reset_RBI_tb : std_logic;
    signal Start_SI_tb : std_logic;
    signal NewCipherkey_SI_tb : std_logic;
    signal Busy_SO_tb : std_logic;
    signal Plaintext_DI_tb  : std_logic_vector(127 downto 0);
    signal Cipherkey_DI_tb  : std_logic_vector(127 downto 0);
    signal Ciphertext_DO_tb : std_logic_vector(127 downto 0));

begin
uut: aes128 port map (
            Clk_CI => clk, 
            Reset_RBI => Reset_RBI_tb, 
            Start_SI => Start_SI_tb,
            NewCipherkey_SI => NewCipherkey_SI_tb,
            Busy_SO => Busy_SO_tb,
            Plaintext_DI => Plaintext_DI_tb,
            Cipherkey_DI => Cipherkey_DI_tb,
            Ciphertext_DO => Ciphertext_DO_tb
            );
            
stim: process
    begin
        Reset_RBI_tb <= '1';
        wait for period;
        Reset_RBI_tb <= '0';
        Plaintext_DI_tb <= x"00112233445566778899aabbccddeeff";
        Cipherkey_DI_tb <= x"000102030405060708090a0b0c0d0e0f";
        NewCipherkey_SI_tb <= '1';
        Start_SI_tb <= '1';
        wait for period;
        Start_SI_tb <= '0';
        NewCipherkey_SI_tb <= '0';
        wait until busy = '0';
        end_sim = true;
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
