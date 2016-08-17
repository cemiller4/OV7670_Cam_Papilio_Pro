-- Listing 7.1
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity uart_rx is
   generic(
      DBIT: integer:=8;     -- # data bits
      SB_TICK: integer:=16  -- # ticks for stop bits
   );
   port(
      clk_i, reset_i: in std_logic;
      rx_i: in std_logic;
      s_tick_i: in std_logic;
      rx_done_tick_o: out std_logic;
      dout_o: out std_logic_vector(7 downto 0)
   );
end uart_rx ;

architecture arch of uart_rx is
   type state_type is (IDLE, START, DATA, STOP);
   signal state_reg, state_next: state_type;
   signal s_reg, s_next: unsigned(3 downto 0);
   signal n_reg, n_next: unsigned(2 downto 0);
   signal b_reg, b_next: std_logic_vector(7 downto 0);
	
begin
   -- FSMD state & data registers
   process(clk_i,reset_i)
   begin
      if reset_i='1' then
         state_reg <= idle;
         s_reg <= (others=>'0');
         n_reg <= (others=>'0');
         b_reg <= (others=>'0');
      elsif rising_edge(clk_i) then
         state_reg <= state_next;
         s_reg <= s_next;
         n_reg <= n_next;
         b_reg <= b_next;
      end if;
   end process;

   -- next-state logic & data path functional units/routing
   process(state_reg, s_reg, n_reg, b_reg, s_tick_i, rx_i)
   begin
      state_next <= state_reg;
      s_next <= s_reg;
      n_next <= n_reg;
      b_next <= b_reg;
      rx_done_tick_o <='0';
		
      case state_reg is
         when IDLE =>
            if rx_i='0' then
               state_next <= START;
               s_next <= (others=>'0');
            end if;
				
         when START =>
            if (s_tick_i = '1') then
               if s_reg=7 then
                  state_next <= DATA;
                  s_next <= (others=>'0');
                  n_next <= (others=>'0');
               else
                  s_next <= s_reg + 1;
               end if;
            end if;
				
         when DATA =>
            if (s_tick_i = '1') then
               if s_reg=15 then
                  s_next <= (others=>'0');
                  b_next <= rx_i & b_reg(7 downto 1) ;
                  if n_reg=(DBIT-1) then
                     state_next <= STOP ;
                  else
                     n_next <= n_reg + 1;
                  end if;
               else
                  s_next <= s_reg + 1;
               end if;
            end if;
				
         when STOP =>
            if (s_tick_i = '1') then
               if s_reg=(SB_TICK-1) then
                  state_next <= IDLE;
                  rx_done_tick_o <='1';
               else
                  s_next <= s_reg + 1;
               end if;
            end if;
      end case;
   end process;
   dout_o <= b_reg;
end arch;