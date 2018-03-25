----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/22/2018 08:33:18 PM
-- Design Name: 
-- Module Name: keyGeneration - Behavioral
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


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.aes128Pkg.all;


entity keyGeneration is
    Port ( key_in : in STD_LOGIC_VECTOR (127 downto 0);
           rcon : in STD_LOGIC_VECTOR (7 downto 0);
           key_out : out STD_LOGIC_VECTOR (127 downto 0));
end keyGeneration;

architecture dataflow of keyGeneration is
  -----------------------------------------------------------------------------
  -- Type definitions
  -----------------------------------------------------------------------------
  type expkeyArrayType is array (0 to 3) of Word;

  -----------------------------------------------------------------------------
  -- Function declarations
  -----------------------------------------------------------------------------
  -- purpose: Provides an exclusive-or (XOR) operation for words.
  function "xor" (
    left  : Word;
    right : Word) return Word is
    variable Result : Word;
  begin
    Result(0) := left(0) xor right(0);
    Result(1) := left(1) xor right(1);
    Result(2) := left(2) xor right(2);
    Result(3) := left(3) xor right(3);
    return Result;
  end "xor";

  -- purpose: Converts a word to a std_logic_vector. The 0-th byte of the word
  --          becomes the most significant byte of the std_logic_vector.
  function conv_std_logic_vector (input : Word) return std_logic_vector is
  begin  -- function conv_std_logic_vector
    return input(0) & input(1) & input(2) & input(3);
  end function conv_std_logic_vector;

  -- purpose: Converts four words (i.e., a matrix) to a std_logic_vector.
  function conv_std_logic_vector (
    column0 : Word;
    column1 : Word;
    column2 : Word;
    column3 : Word)
    return std_logic_vector is
  begin  -- function conv_std_logic_vector
    return
      column0(0) & column0(1) & column0(2) & column0(3) &
      column1(0) & column1(1) & column1(2) & column1(3) &
      column2(0) & column2(1) & column2(2) & column2(3) &
      column3(0) & column3(1) & column3(2) & column3(3);
  end function conv_std_logic_vector;

  -----------------------------------------------------------------------------
  -- Component declarations
  -----------------------------------------------------------------------------
  component subWord is
    port (
      In_DI  : in  Word;
      Out_DO : out Word);
  end component subWord;

  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------
  signal ExpKey_D : expkeyArrayType;
  signal SubWordIn_D : Word;
  signal SubWordOut_D : Word;
  signal Rcon_D : Word;
  
begin  -- architecture dataflow

  -----------------------------------------------------------------------------
  -- Component instantiations
  -----------------------------------------------------------------------------
    subWords : subWord
      port map (
        In_DI  => SubWordIn_D,
        Out_DO => SubWordOut_D);
  -----------------------------------------------------------------------------

    key_out <= conv_std_logic_vector(ExpKey_D(0), ExpKey_D(1), ExpKey_D(2), ExpKey_D(3));

    SubWordIn_D <= conv_word(key_in(31 downto 0));
    Rcon_D(0) <= SubWordOut_D(1) xor rcon;
    Rcon_D(1) <= SubWordOut_D(2);
    Rcon_D(2) <= SubWordOut_D(3);
    Rcon_D(3) <= SubWordOut_D(0);
    -- Calculate the next expanded key 
    ExpKey_D(0) <= Rcon_D xor conv_word(key_in(127 downto 96));                                                             
    ExpKey_D(1) <= Rcon_D xor conv_word(key_in(127 downto 96)) xor conv_word(key_in(95 downto 64));                                           
    ExpKey_D(2) <= Rcon_D xor conv_word(key_in(127 downto 96)) xor conv_word(key_in(95 downto 64)) xor conv_word(key_in(63 downto 32));                    
    ExpKey_D(3) <= Rcon_D xor conv_word(key_in(127 downto 96)) xor conv_word(key_in(95 downto 64)) xor conv_word(key_in(63 downto 32)) xor conv_word(key_in(31 downto 0));
    
end architecture dataflow;
