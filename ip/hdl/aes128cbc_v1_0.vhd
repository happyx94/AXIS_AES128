library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity aes128cbc_v1_0 is
	generic (
		AES_DATA_WIDTH	: integer	:= 128
	);
	port (
	    new_key : in std_logic;
	    cipher_key : in std_logic_vector(AES_DATA_WIDTH-1 downto 0);
		-- Ports of Axi Slave Bus Interface S00_AXIS
		s00_axis_aclk	: in std_logic;
		s00_axis_aresetn	: in std_logic;
		s00_axis_tready	: out std_logic;
		s00_axis_tdata	: in std_logic_vector(AES_DATA_WIDTH-1 downto 0);
		s00_axis_tstrb	: in std_logic_vector((AES_DATA_WIDTH/8)-1 downto 0);
		s00_axis_tlast	: in std_logic;
		s00_axis_tvalid	: in std_logic;

		-- Ports of Axi Master Bus Interface M00_AXIS
		m00_axis_aclk	: in std_logic;
		m00_axis_aresetn	: in std_logic;
		m00_axis_tvalid	: out std_logic;
		m00_axis_tdata	: out std_logic_vector(AES_DATA_WIDTH-1 downto 0);
		m00_axis_tstrb	: out std_logic_vector((AES_DATA_WIDTH/8)-1 downto 0);
		m00_axis_tlast	: out std_logic;
		m00_axis_tready	: in std_logic
	);
end aes128cbc_v1_0;

architecture arch_imp of aes128cbc_v1_0 is

	type state is ( IDLE,      -- Initial/idle state 
	                INIT,     -- Start encryption         
	                RUNNING,   -- In the middle of ncryption process
	                READY      -- Ciphertext ready to send
	                ); 
	                
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
    
    signal current_state : state;
    signal next_state : state;
    
    signal busy : std_logic;
    signal start : std_logic;
    
    signal last : std_logic;
begin

encryptor: aes128 port map (
            Clk_CI => s00_axis_aclk, 
            Reset_RBI => s00_axis_aresetn, 
            Start_SI => start,
            NewCipherkey_SI => new_key,
            Busy_SO => busy,
            Plaintext_DI => s00_axis_tdata,
            Cipherkey_DI => cipher_key,
            Ciphertext_DO => m00_axis_tdata
            );

    output: process(current_state)
    begin
        case current_state is
            when IDLE =>
                s00_axis_tready <= '0';
                m00_axis_tvalid <= '0';
                start <= '0';
                last <= '0';
                m00_axis_tlast <= '0';
            when INIT =>
                s00_axis_tready <= '1';
                m00_axis_tvalid <= '0';
                start <= '1';
                last <= s00_axis_tlast;
                m00_axis_tlast <= '0';
            when RUNNING =>
                s00_axis_tready <= '0';
                m00_axis_tvalid <= '0';
                start <= '0';
                last <= last;
                m00_axis_tlast <= '0';
            when READY =>
                s00_axis_tready <= '0';
                m00_axis_tvalid <= '1';
                start <= '0';
                m00_axis_tlast <= last;
        end case; 
    end process;

    sreg: process (s00_axis_aclk, s00_axis_aresetn)
    begin
        if s00_axis_aresetn = '0' then
            current_state <= IDLE;
        elsif rising_edge(s00_axis_aclk) then
            current_state <= next_state;
        end if;
    end process;

    next_state_comb: process (current_state, s00_axis_tvalid, busy, m00_axis_tready)
    begin
        case current_state is
            when IDLE => 
                if s00_axis_tvalid = '1' then
                    next_state <= INIT;
                else
                    next_state <= IDLE;
                end if;
            when INIT =>
                next_state <= RUNNING;
            when RUNNING =>
                if busy = '1' then
                    next_state <= RUNNING;
                else
                    next_state <= READY;
                end if;
            when READY =>
                if m00_axis_tready = '1' then
                    next_state <= IDLE;
                else
                    next_state <= READY;
                end if;
        end case;
    end process;

end arch_imp;
