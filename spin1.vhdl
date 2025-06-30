architecture spin1 of leds is
  signal nrst : std_logic := '0';
  signal clk_4hz: std_logic;
  signal leds : std_ulogic_vector (1 to 5);
begin
  (LED1, LED2, LED3, LED4, LED5) <= leds;

  process (CLK)
    variable cnt : unsigned (1 downto 0) := "00";
  begin
    if rising_edge (CLK) then
      if cnt = 3 then
        nrst <= '1';
      else
        cnt := cnt + 1;
      end if;
    end if;
  end process;

  process (CLK)
    --  3_000_000 is 0x2dc6c0
    variable counter : unsigned (23 downto 0);
  begin
    if rising_edge(CLK) then
      if nrst = '0' then
        counter := x"000000";
      else
        if counter = 2_999_999 then
          counter := x"000000";
          clk_4hz <= '1';
        else
          counter := counter + 1;
          clk_4hz <= '0';
        end if;
      end if;
    end if;
  end process;

  process (CLK)
  begin
    if rising_edge(CLK) then
      if nrst = '0' then
        -- Initialize
        leds <= "11000";
      elsif clk_4hz = '1' then
        --  Rotate
        leds <= (leds (4), leds (1), leds (2), leds (3), '0');
      end if;
    end if;
  end process;
end spin1;