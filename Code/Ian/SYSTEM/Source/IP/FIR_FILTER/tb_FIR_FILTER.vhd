-- ================================================================================
-- Legal Notice: Copyright (C) 1991-2006 Altera Corporation
-- Any megafunction design, and related net list (encrypted or decrypted),
-- support information, device programming or simulation file, and any other
-- associated documentation or information provided by Altera or a partner
-- under Altera's Megafunction Partnership Program may be used only to
-- program PLD devices (but not masked PLD devices) from Altera.  Any other
-- use of such megafunction design, net list, support information, device
-- programming or simulation file, or any other related documentation or
-- information is prohibited for any other purpose, including, but not
-- limited to modification, reverse engineering, de-compiling, or use with
-- any other silicon devices, unless such use is explicitly licensed under
-- a separate agreement with Altera or a megafunction partner.  Title to
-- the intellectual property, including patents, copyrights, trademarks,
-- trade secrets, or maskworks, embodied in any such megafunction design,
-- net list, support information, device programming or simulation file, or
-- any other related documentation or information provided by Altera or a
-- megafunction partner, remains with Altera, the megafunction partner, or
-- their respective licensors.  No other licenses, including any licenses
-- needed under any third party's intellectual property, are provided herein.
-- ================================================================================
--

-- Generated by: FIR Compiler 13.0
-- Generated on: 31/08/2015 6:28:35 PM

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
entity tb_fir_filter is
--START MEGAWIZARD INSERT CONSTANTS
  constant FIR_INPUT_FILE_c  : string := "fir_filter_input.txt";
  constant FIR_OUTPUT_FILE_c : string := "fir_filter_output.txt";
  constant NUM_OF_CHANNELS_c        : natural := 1;
  constant DATA_WIDTH_c             : natural := 12;
  constant CHANNEL_OUT_WIDTH_c      : natural := 0;
  constant OUT_WIDTH_c              : natural := 28;
  constant COEF_SET_ADDRESS_WIDTH_c : natural := 0;
  constant COEF_RELOAD_BIT_WIDTH_c  : natural := 10;

--END MEGAWIZARD INSERT CONSTANTS
end entity tb_fir_filter;


--library work;
--library auk_dspip_lib;

-------------------------------------------------------------------------------

architecture rtl of tb_fir_filter is
  
  signal ast_sink_data    : std_logic_vector (DATA_WIDTH_c-1 downto 0) := (others => '0');
  signal ast_source_data  : std_logic_vector (OUT_WIDTH_c-1 downto 0);
  signal ast_sink_error   : std_logic_vector (1 downto 0)              := (others => '0');
  signal ast_source_error : std_logic_vector (1 downto 0);
  signal ast_sink_valid   : std_logic                                  := '0';
  signal ast_source_valid : std_logic;
  signal ast_source_ready : std_logic                                  := '0';
  signal clk            : std_logic := '0';
  signal reset_testbench        : std_logic := '0';
  signal reset_design   : std_logic;
  signal eof            : std_logic;
  signal ast_sink_ready : std_logic;
  signal start : std_logic;
  signal cnt   : natural range 0 to NUM_OF_CHANNELS_c;
  constant tclk           : time := 10 ns;
  constant time_lapse_max : time := 60 us;
  signal time_lapse       : time;
begin
  
  DUT : entity work.fir_filter
    port map (
      clk                => clk,
      reset_n            => reset_design,
      ast_sink_ready     => ast_sink_ready,
      ast_sink_data      => ast_sink_data,
      ast_source_data    => ast_source_data,
      ast_sink_valid     => ast_sink_valid,
      ast_source_valid   => ast_source_valid,
      ast_source_ready   => ast_source_ready,
      ast_sink_error   => ast_sink_error,
      ast_source_error => ast_source_error);
  -- for example purposes, the ready signal is always asserted.
  ast_source_ready <= '1';

  -- no input error
  ast_sink_error <= (others => '0');

  -- start valid for first cycle to indicate that the file reading should start.
  start_p : process (clk, reset_testbench)
  begin
    if reset_testbench = '0' then
      start <= '1';
    elsif rising_edge(clk) then
      if ast_sink_valid = '1' and ast_sink_ready = '1' then
        start <= '0';
      end if;
    end if;
  end process start_p;
  -----------------------------------------------------------------------------------------------
  -- Read input data from file                                                                 
  -----------------------------------------------------------------------------------------------
  source_model : process(clk) is
    file in_file     : text open read_mode is FIR_INPUT_FILE_c;
    variable data_in : integer;
    variable indata  : line;
  begin
    if rising_edge(clk) then
      if(reset_testbench = '0') then
        ast_sink_data  <= std_logic_vector(to_signed(0, DATA_WIDTH_c)) after tclk/4;
        ast_sink_valid <= '0' after tclk/4;
        eof            <= '0';
      else
        if not endfile(in_file) and (eof = '0') then
          eof <= '0';
          if((ast_sink_valid = '1' and ast_sink_ready = '1') or
             (start = '1'and not (ast_sink_valid = '1' and ast_sink_ready = '0'))) then
            readline(in_file, indata);
            read(indata, data_in);
            ast_sink_valid <= '1' after tclk/4;
            ast_sink_data  <= std_logic_vector(to_signed(data_in, DATA_WIDTH_c)) after tclk/4;
          else
            ast_sink_valid <= '1' after tclk/4;
            ast_sink_data  <= ast_sink_data after tclk/4;
          end if;
        else
          eof            <= '1';
          ast_sink_valid <= '0' after tclk/4;
          ast_sink_data  <= std_logic_vector(to_signed(0, DATA_WIDTH_c)) after tclk/4;
        end if;
      end if;
    end if;
  end process source_model;
  ---------------------------------------------------------------------------------------------
  -- Write FIR output to file                                               
  ---------------------------------------------------------------------------------------------

  sink_model : process(clk) is
    file ro_file   : text open write_mode is FIR_OUTPUT_FILE_c;
    variable rdata : line;
    variable data_r : integer;
  begin
    if rising_edge(clk) then
      if(ast_source_valid = '1' and ast_source_ready = '1') then
        data_r := to_integer(signed(ast_source_data));
        write(rdata, data_r);
        writeline(ro_file, rdata);
      end if;
    end if;
  end process sink_model;
-------------------------------------------------------------------------------
-- clock generator
-------------------------------------------------------------------------------      
  clkgen : process
  begin  -- process clkgen
    if eof = '1' then
      clk <= '0';
      assert FALSE
        report "NOTE: Stimuli ended" severity note;
      wait;
    elsif time_lapse >= time_lapse_max then
      clk <= '0';
      assert FALSE
        report "ERROR: Reached time_lapse_max without activity, probably simulation is stuck!" severity Error;
      wait;      
    else
      clk <= '0';
      wait for tclk/2;
      clk <= '1';
      wait for tclk/2;
    end if;
  end process clkgen;

  monitor_toggling_activity : process(clk, reset_testbench,
                                      ast_source_data, ast_source_valid)
  begin
    if reset_testbench = '0' then
      time_lapse <= 0 ns;
    elsif ast_source_data'event or ast_source_valid'event then
      time_lapse <= 0 ns;
    elsif rising_edge(clk) then
      if time_lapse < time_lapse_max then
        time_lapse <= time_lapse + tclk;
      end if;
    end if;
  end process monitor_toggling_activity;


-------------------------------------------------------------------------------
-- reset generator
-------------------------------------------------------------------------------
  reset_testbench_gen : process
  begin  -- process resetgen
    reset_testbench <= '1';
    wait for tclk/4;
    reset_testbench <= '0';
    wait for tclk*2;
    reset_testbench <= '1';
    wait;
  end process reset_testbench_gen;
  reset_design_gen : process
  begin  -- process resetgen
    reset_design <= '1';
    wait for tclk/4;
    reset_design <= '0'; 
    wait for tclk*2;
    reset_design <= '1';
    wait for tclk*80;
    reset_design <= '1';
    wait for tclk*260*2;
    reset_design <= '1';
    wait;
  end process reset_design_gen;

-------------------------------------------------------------------------------
-- control signals
-------------------------------------------------------------------------------

end architecture rtl;
