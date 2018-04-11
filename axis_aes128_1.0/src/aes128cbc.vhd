-------------------------------------------------------------------------------
--! @file       aes128cbc.vhd
--! @brief      High-throughput implementation of AES-128 CBC mode
--! @project    VLSI Book - AES-128 Example
--! @author     Michael Muehlberghuber (mbgh@iis.ee.ethz.ch), Hsiang-Ju Lai
--! @company    Integrated Systems Laboratory, ETH Zurich, Stony Brook University
--! @copyright  Copyright (C) 2014 Integrated Systems Laboratory, ETH Zurich
--! @date       2014-06-05
--! @updated    2014-10-15
--! @platform   Simulation: ModelSim; Synthesis: Synopsys
--! @standard   VHDL'93/02
-------------------------------------------------------------------------------
-- Revision Control System Information:
-- File ID      :  $Id: aes128.vhd 21 2014-10-17 16:06:52Z u59323933 $
-- Revision     :  $Revision: 21 $
-- Local Date   :  $Date: 2014-10-17 18:06:52 +0200 (Fri, 17 Oct 2014) $
-- Modified By  :  $Author: u59323933 $
-------------------------------------------------------------------------------
-- Major Revisions:
-- Date        Version   Author    Description
-- 2014-06-05  1.0       michmueh  Created
-- 2014-06-10  1.1       michmueh  Removed controlling FSM and replaced the
--                                 cipher state register enables computation
--                                 with a simple shift register.
-- 2018-03-22  2.0       hslai     convert it to cbc mode cipher
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.aes128Pkg.all;

-------------------------------------------------------------------------------
--! @brief High-throughput implementation of AES-128
--!
--! The present design implements the cipher of the 128-bit version of the
--! Advanced Encryption Standard (AES). Since the design targets a
--! high-throughput implementation, both the key expansion and the actual cipher
--! are pipeline.
--!
--! Inputs and outputs are registered. - While the plaintext and the ciphertext
--! are registered in the top entity, the cipherkey is registered within the key
--! expansion entity. Due to the input buffering, the actual encryption starts
--! with a delay of one clock cycle. After that, both the key expansion and the
--! encryption are executed "in parallel".
-------------------------------------------------------------------------------
entity aes128cbc is
  
  port (
    --! @brief System clock.
    Clk_CI : in std_logic;

    --! @brief Synchronous, active-high reset.
    Reset_RBI : in std_logic;

    Set_IV : in std_logic;

    --! @brief Starts the actual encryption process.
    --! <TABLE BORDER="0">
    --! <TR><TD>0</TD><TD>...</TD><TD>Do not start the encryption.</TD></TR>
    --! <TR><TD>1</TD><TD>...</TD><TD>Start the encryption (value has to be applied only for a single clock cycle).</TD></TR>
    --! </TABLE>
    Start_SI : in std_logic;

    --! @brief Determines whether a the module is currently processing or not.
    --! <TABLE BORDER="0">
    --! <TR><TD>0</TD><TD>...</TD><TD>Module is in IDLE mode.</TD></TR>
    --! <TR><TD>1</TD><TD>...</TD><TD>Module is currently encrypting.</TD></TR>
    --! </TABLE>
    Busy_SO : out std_logic;

    --! @brief The plaintext block to be encrypted.
    Plaintext_DI  : in  std_logic_vector(127 downto 0);
    --! @brief the cipherkey to be used for encryption.
    Cipherkey_DI  : in  std_logic_vector(127 downto 0);
    --! @brief The resulting ciphertext.
    Ciphertext_DO : out std_logic_vector(127 downto 0));
    
end entity aes128cbc;

-------------------------------------------------------------------------------
--! @brief Behavioral architecture of AES-128.
-------------------------------------------------------------------------------
architecture Behavioral of aes128cbc is

  -----------------------------------------------------------------------------
  -- Types
  -----------------------------------------------------------------------------
--  type stateArrayType is array (0 to 9) of Matrix;
  type rconConstantsArray is array (0 to 10) of std_logic_vector(7 downto 0);
  
  ------------------------------------------------------------------------
  -- Constants                                                            
  ------------------------------------------------------------------------
  constant RCON : rconConstantsArray := (x"01", x"02", x"04", x"08", x"10", x"20", x"40", x"80", x"1B", x"36", x"36");

  -----------------------------------------------------------------------------
  -- Component declarations
  -----------------------------------------------------------------------------
  component keyGeneration is
    port (
      key_in : in STD_LOGIC_VECTOR (127 downto 0);
      rcon : in STD_LOGIC_VECTOR (7 downto 0);
      key_out : out STD_LOGIC_VECTOR (127 downto 0));
  end component keyGeneration;

  component cipherRound is
    port (
      StateIn_DI  : in  Matrix;
      Roundkey_DI : in  std_logic_vector(127 downto 0);
      StateOut_DO : out Matrix);
  end component cipherRound;

  component subMatrix is
    port (
      In_DI  : in  Matrix;
      Out_DO : out Matrix);
  end component subMatrix;


  -----------------------------------------------------------------------------
  -- Functions
  -----------------------------------------------------------------------------
  -- purpose: Converts a std_logic_vector into a matrix. 
  function conv_matrix (
    input : std_logic_vector(127 downto 0))
    return Matrix is
    variable result : Matrix;
  begin  -- function conv_matrix
    result(0) := conv_word(input(127 downto 96));
    result(1) := conv_word(input(95 downto 64));
    result(2) := conv_word(input(63 downto 32));
    result(3) := conv_word(input(31 downto 0));
    return result;
  end function conv_matrix;

  -- purpose: Converts a matrix to a std_logic_vector. The 0-th byte of the
  --          first word of the matrix becomes the most significant byte of
  --          the std_logic_vector.
  function conv_std_logic_vector (
    input : Matrix)
    return std_logic_vector is
  begin  -- function conv_std_logic_vector
    return
      input(0)(0) & input(0)(1) & input(0)(2) & input(0)(3) &
      input(1)(0) & input(1)(1) & input(1)(2) & input(1)(3) &
      input(2)(0) & input(2)(1) & input(2)(2) & input(2)(3) &
      input(3)(0) & input(3)(1) & input(3)(2) & input(3)(3);
  end function conv_std_logic_vector;


  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------

  -- Registers.
  signal CipherState_DN, CipherState_DP     : Matrix;
  signal Ciphertext_DP                      : Matrix;

  -- Some intermediate signals.
  signal Roundkey_DP               : std_logic_vector(127 downto 0);
  signal Roundkey_DN               : std_logic_vector(127 downto 0);
  signal Roundkey_IN               : std_logic_vector(127 downto 0);
  signal LastSubMatrixOut_D        : Matrix;
  signal rcon_n : std_logic_vector(7 downto 0);

  signal n_round : integer range 0 to 10;
  signal n_round_next : integer range 0 to 10;
  
begin  -- architecture Behavioral

  -----------------------------------------------------------------------------
  -- Component instantiations
  -----------------------------------------------------------------------------
  -- S-boxes of the last round.
  lastSubMatrix : subMatrix
    port map (
      In_DI  => CipherState_DN,
      Out_DO => LastSubMatrixOut_D);
      
  -- Perform last round (i.e., round without the "MixColumn" step) and
      -- calculate the final state, which is equal to the ciphertext.

  -- Perform full rounds (i.e., rounds one to nine).
  
    key_gen: keyGeneration 
        port map(
            key_in => Roundkey_IN,
            rcon => rcon_n,
            key_out => Roundkey_DN
            );

    cipherRounds : cipherRound
        port map (
            StateIn_DI  => CipherState_DP,
            Roundkey_DI => Roundkey_DP,
            StateOut_DO => CipherState_DN);
   
    Roundkey_IN <= Cipherkey_DI when n_round = 0 else Roundkey_DP;
    rcon_n <= RCON(n_round);
    Ciphertext_DO <= conv_std_logic_vector(Ciphertext_DP); 
   


    processor: process(Clk_CI, Reset_RBI)
    begin
        if Reset_RBI = '0' then
            Ciphertext_DP <= conv_matrix((others => '0'));
        elsif rising_edge(Clk_CI) then
            if n_round_next = 0 then
               if Set_IV = '1' then
                   Ciphertext_DP <= conv_matrix(Cipherkey_DI);
               end if;
            elsif n_round_next = 1 then
               CipherState_DP <= conv_matrix(Cipherkey_DI xor (Plaintext_DI xor conv_std_logic_vector(Ciphertext_DP)));
               Roundkey_DP <= Roundkey_DN;
            elsif n_round_next > 1 and n_round_next < 10 then
               CipherState_DP <= CipherState_DN;
               Roundkey_DP <= Roundkey_DN;
            elsif n_round_next = 10 then
               Ciphertext_DP <= shift_rows(LastSubMatrixOut_D) xor Roundkey_DN;
            end if;
        end if;    
    end process;

    output_comb: process(n_round)
    begin
        if n_round = 0 then
            Busy_SO <= '0';
        elsif n_round = 1 then
            Busy_SO <= '1';
        elsif n_round > 1 and n_round < 10 then
            Busy_SO <= '1';
        else -- n_round = 10
            Busy_SO <= '1';
        end if;
    end process;

    next_round_sreg: process(Clk_CI, Reset_RBI)
    begin
        if Reset_RBI = '0' then
            n_round <= 0;
        elsif rising_edge(Clk_CI) then
            n_round <= n_round_next;
        end if;    
    end process;

    next_round_comb: process(Start_SI, n_round)
    begin
        if Start_SI = '1' and n_round = 0 then
            n_round_next <= 1;
        elsif n_round > 0 and n_round < 10 then
            n_round_next <= n_round + 1;
        else -- n_round = 10 or (n_round = 0 and !Start_SI)
            n_round_next <= 0;
        end if;  
    end process;
    
    
end architecture Behavioral;
