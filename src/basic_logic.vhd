library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity mesafelcd is
    Port ( clk       : in STD_LOGIC;                        -- 100 MHz Clock
           echo      : in STD_LOGIC;                        -- Sensör Echo
           
           -- TEK BUTON
           btn_control : in STD_LOGIC;                      -- L3: Tek Kontrol Butonu
           
           -- ÇIKI?LAR
           trig      : out STD_LOGIC;                       -- Sensör Trig
           buzzer    : out STD_LOGIC;                       -- Buzzer
           
           -- LEDLER (Mesafe Uyar?)
           led_red   : out STD_LOGIC; 
           led_yellow: out STD_LOGIC;                       
           led_green : out STD_LOGIC;                       
           
           -- LEDLER (Hangi Modday?z? Debug için)
           led_state_0 : out STD_LOGIC;                     -- Durum Bit 0
           led_state_1 : out STD_LOGIC;                     -- Durum Bit 1
           
           -- LCD Portlar?
           lcd_rs    : out STD_LOGIC;                       
           lcd_en    : out STD_LOGIC;                       
           lcd_d     : out STD_LOGIC_VECTOR(7 downto 4);

           -- BASYS 3 DAH?L? 7-SEGMENT PORTLARI
           seg       : out STD_LOGIC_VECTOR(6 downto 0);
           an        : out STD_LOGIC_VECTOR(3 downto 0);
           dp        : out STD_LOGIC
           );
end mesafelcd;

architecture Behavioral of mesafelcd is

    -- Sabitler
    constant C_CLK_FREQ      : integer := 100_000_000;
    constant C_CLKS_PER_UNIT : integer := 58;           
    
    -- DURUM MAK?NES? DE???KENLER?
    -- 0: Kapal?, 1: Hepsi Aç?k, 2: Sadece LCD, 3: Sadece 7-Seg
    signal current_state : integer range 0 to 3 := 0; 
    
    -- BUTON DEBOUNCE S?NYALLER?
    signal btn_sync     : std_logic := '0';
    signal debounce_cnt : integer range 0 to 1000000 := 0;
    signal btn_stable   : std_logic := '0';
    signal btn_prev     : std_logic := '0';
    signal btn_pulse    : std_logic := '0'; -- Tek seferlik tetik

    -- Mant?ksal Yetkiler (State'e göre belirlenir)
    signal system_active : std_logic;
    signal enable_lcd    : std_logic;
    signal enable_seg    : std_logic;

    -- Mesafe Sinyalleri
    signal count_timer   : integer range 0 to 6000000 := 0; 
    signal sonic_dist    : integer range 0 to 40000 := 0;     
    signal final_dist    : integer range 0 to 40000 := 0;     
    signal unit_counter  : integer range 0 to C_CLKS_PER_UNIT := 0;
    signal echo_sync     : std_logic := '0'; 
    signal echo_last     : std_logic := '0';

    signal digit0, digit1, digit2, digit3 : integer range 0 to 9 := 0;

    -- Ses ve I??k
    signal tone_timer  : integer := 0;
    signal tone_out    : std_logic := '0';
    signal beep_timer  : integer := 0;
    signal beep_enable : std_logic := '0';

    -- LCD Sinyalleri
    type lcd_state_type is (st_power_on, st_init_sq1, st_init_sq2, st_init_sq3, st_init_sq4, 
                            st_init_cmd, st_idle, st_send_upper, st_pulse_1, st_send_lower, st_pulse_2, st_wait, st_wait_switch);
    signal state : lcd_state_type := st_power_on;
    signal return_state : lcd_state_type := st_idle; 
    signal lcd_timer : integer := 0;
    signal lcd_data_buf : std_logic_vector(7 downto 0) := (others => '0');
    signal lcd_rs_buf   : std_logic := '0';
    signal init_step    : integer range 0 to 10 := 0;
    signal char_index   : integer range 0 to 32 := 0;
    signal single_nibble : std_logic := '0'; 

    type text_array is array (0 to 7) of std_logic_vector(7 downto 0);
    constant MSG_LINE1 : text_array := (x"4D", x"65", x"73", x"61", x"66", x"65", x"3A", x"20");

    -- BASYS 3 EKRAN Sinyalleri
    signal refresh_counter : std_logic_vector(19 downto 0) := (others => '0');
    signal LED_activating_counter : std_logic_vector(1 downto 0);
    signal internal_seg_val : integer range 0 to 9;

begin

    -------------------------------------------------------------------------
    -- 0. TEK BUTON ?LE 4 A?AMALI KONTROL
    -------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            -- A) Buton Debounce (Gürültü Temizleme)
            btn_sync <= btn_control;

            if btn_sync = '1' then
                if debounce_cnt < 500000 then -- 5ms bekle
                    debounce_cnt <= debounce_cnt + 1;
                else
                    btn_stable <= '1';
                end if;
            else
                debounce_cnt <= 0;
                btn_stable <= '0';
            end if;

            -- B) Pulse Üretme (Bas?ld??? an? yakala)
            if btn_stable = '1' and btn_prev = '0' then
                btn_pulse <= '1';
            else
                btn_pulse <= '0';
            end if;
            btn_prev <= btn_stable;

            -- C) Durum De?i?tirme (0 -> 1 -> 2 -> 3 -> 0)
            if btn_pulse = '1' then
                if current_state = 3 then
                    current_state <= 0; -- 4. Bas??ta ba?a dön (Kapat)
                else
                    current_state <= current_state + 1; -- Di?er bas??larda art?r
                end if;
            end if;
        end if;
    end process;

    -- DURUMA GÖRE YETK?LER? AYARLA
    -- State 0: Kapal?
    -- State 1: Hepsi Aç?k
    -- State 2: LCD Aç?k, Seg Kapal?
    -- State 3: LCD Kapal?, Seg Aç?k
    
    system_active <= '1' when current_state /= 0 else '0';  -- 0 hariç her durumda sistem aktif
    enable_lcd    <= '1' when (current_state = 1 or current_state = 2) else '0';
    enable_seg    <= '1' when (current_state = 1 or current_state = 3) else '0';

    -- DEBUG LEDLER? (Hangi a?amada oldu?umuzu gösterir)
    -- 00: Kapal?, 01: Hepsi, 10: LCD, 11: Seg
    led_state_0 <= '1' when (current_state = 1 or current_state = 3) else '0';
    led_state_1 <= '1' when (current_state = 2 or current_state = 3) else '0';


    -------------------------------------------------------------------------
    -- 1. BASYS 3 DAH?L? EKRAN SÜRÜCÜSÜ (enable_seg kontrolünde)
    -------------------------------------------------------------------------
    process(clk)
    begin 
        if rising_edge(clk) then
            refresh_counter <= refresh_counter + 1;
        end if;
    end process;
    
    LED_activating_counter <= refresh_counter(19 downto 18);

    process(LED_activating_counter, enable_seg, digit0, digit1, digit2, digit3)
    begin
        if enable_seg = '0' then
            an <= "1111"; internal_seg_val <= 0; dp <= '1';
        else
            case LED_activating_counter is
                when "00" => an <= "1110"; internal_seg_val <= digit0; dp <= '1';    
                when "01" => an <= "1101"; internal_seg_val <= digit1; dp <= '1';    
                when "10" => an <= "1011"; internal_seg_val <= digit2; dp <= '0';    
                when "11" => an <= "0111"; internal_seg_val <= digit3; dp <= '1';
                when others => an <= "1111"; internal_seg_val <= 0; dp <= '1';
            end case;
        end if;
    end process;

    process(internal_seg_val)
    begin
        case internal_seg_val is
            when 0 => seg <= "1000000"; when 1 => seg <= "1111001"; when 2 => seg <= "0100100"; when 3 => seg <= "0110000"; 
            when 4 => seg <= "0011001"; when 5 => seg <= "0010010"; when 6 => seg <= "0000010"; when 7 => seg <= "1111000"; 
            when 8 => seg <= "0000000"; when 9 => seg <= "0010000"; when others => seg <= "1111111"; 
        end case;
    end process;

    -------------------------------------------------------------------------
    -- 2. SENSÖR, LED, BUZZER (Sistem Aktifse Çal???r)
    -------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if tone_timer < 20000 then tone_timer <= tone_timer + 1; else tone_timer <= 0; tone_out <= not tone_out; end if;
            if beep_timer < 12500000 then beep_timer <= beep_timer + 1; else beep_timer <= 0; beep_enable <= not beep_enable; end if;
        end if;
    end process;

    process(final_dist, tone_out, beep_enable, system_active)
    begin
        if system_active = '0' or final_dist = 0 then
            led_green <= '0'; led_red <= '0'; led_yellow <= '0'; buzzer <= '0'; 
        else
            if final_dist <= 500 then led_green <= '0'; led_yellow <='0' ; led_red <= '1'; buzzer <= tone_out; 
            elsif final_dist <= 1000 then led_green <= '0'; led_yellow <= beep_enable; led_red <= '0'; buzzer <= tone_out and beep_enable;
            else led_green <= '1'; led_yellow <='0' ; led_red <= '0'; buzzer <= '0';
            end if;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if count_timer < 6000000 then count_timer <= count_timer + 1; else count_timer <= 0; end if;
            if count_timer < 1000 then 
                if system_active = '1' then trig <= '1'; else trig <= '0'; end if;
                sonic_dist <= 0; unit_counter <= 0; 
            else 
                trig <= '0'; 
            end if;
            
            echo_last <= echo_sync; echo_sync <= echo;
            
            if system_active = '1' then
                if (echo_sync = '1') then
                    if unit_counter < C_CLKS_PER_UNIT then unit_counter <= unit_counter + 1;
                    else unit_counter <= 0; if sonic_dist < 40000 then sonic_dist <= sonic_dist + 1; end if; end if;
                elsif (echo_last = '1' and echo_sync = '0') then final_dist <= sonic_dist; end if;
            else
                final_dist <= 0; 
            end if;
        end if;
    end process;

    process(final_dist)
    begin
        digit0 <= final_dist mod 10; digit1 <= (final_dist / 10) mod 10;
        digit2 <= (final_dist / 100) mod 10; digit3 <= (final_dist / 1000) mod 10;
    end process;

    -------------------------------------------------------------------------
    -- 3. LCD DRIVER (enable_lcd ile kontrol edilir)
    -------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if lcd_timer > 0 then lcd_timer <= lcd_timer - 1;
            else
                case state is
                    when st_power_on => lcd_timer <= 5000000; state <= st_init_sq1;
                    when st_init_sq1 => lcd_data_buf <= x"30"; lcd_rs_buf <= '0'; single_nibble <= '1'; state <= st_send_upper; return_state <= st_init_sq2;
                    when st_init_sq2 => lcd_data_buf <= x"30"; lcd_rs_buf <= '0'; single_nibble <= '1'; state <= st_send_upper; return_state <= st_init_sq3;
                    when st_init_sq3 => lcd_data_buf <= x"30"; lcd_rs_buf <= '0'; single_nibble <= '1'; state <= st_send_upper; return_state <= st_init_sq4;
                    when st_init_sq4 => lcd_data_buf <= x"20"; lcd_rs_buf <= '0'; single_nibble <= '1'; state <= st_send_upper; return_state <= st_init_cmd; init_step <= 0;
                    when st_init_cmd =>
                        single_nibble <= '0'; lcd_rs_buf <= '0';
                        case init_step is
                            when 0 => lcd_data_buf <= x"28"; when 1 => lcd_data_buf <= x"0C"; when 2 => lcd_data_buf <= x"06"; when 3 => lcd_data_buf <= x"01"; when others => state <= st_idle;
                        end case;
                        if init_step <= 3 then state <= st_send_upper; return_state <= st_init_cmd; init_step <= init_step + 1; end if;
                    when st_idle =>
                        if enable_lcd = '0' then
                            lcd_rs_buf <= '0'; lcd_data_buf <= x"01"; state <= st_send_upper; return_state <= st_wait_switch; 
                        else
                            single_nibble <= '0';
                            case char_index is
                                when 0 => lcd_rs_buf <= '0'; lcd_data_buf <= x"80";
                                when 1 to 8 => lcd_rs_buf <= '1'; lcd_data_buf <= MSG_LINE1(char_index - 1);
                                when 9 => lcd_rs_buf <= '0'; lcd_data_buf <= x"C0";
                                when 10 => lcd_rs_buf <= '1'; lcd_data_buf <= std_logic_vector(to_unsigned(digit3, 8) + x"30");
                                when 11 => lcd_rs_buf <= '1'; lcd_data_buf <= std_logic_vector(to_unsigned(digit2, 8) + x"30");
                                when 12 => lcd_rs_buf <= '1'; lcd_data_buf <= x"2E";
                                when 13 => lcd_rs_buf <= '1'; lcd_data_buf <= std_logic_vector(to_unsigned(digit1, 8) + x"30");
                                when 14 => lcd_rs_buf <= '1'; lcd_data_buf <= std_logic_vector(to_unsigned(digit0, 8) + x"30");
                                when 15 => lcd_rs_buf <= '1'; lcd_data_buf <= x"20"; 
                                when 16 => lcd_rs_buf <= '1'; lcd_data_buf <= x"63"; 
                                when 17 => lcd_rs_buf <= '1'; lcd_data_buf <= x"6D"; 
                                when others => char_index <= 0;
                            end case;
                            if char_index <= 17 then state <= st_send_upper; return_state <= st_idle; char_index <= char_index + 1; else char_index <= 0; end if;
                        end if;
                    when st_wait_switch =>
                        if enable_lcd = '1' then state <= st_power_on; else state <= st_wait_switch; end if;
                    when st_send_upper => lcd_rs <= lcd_rs_buf; lcd_d <= lcd_data_buf(7 downto 4); lcd_en <= '0'; lcd_timer <= 5000; state <= st_pulse_1;
                    when st_pulse_1 => lcd_en <= '1'; lcd_timer <= 50000; if single_nibble = '1' then state <= st_wait; else state <= st_send_lower; end if;
                    when st_send_lower => lcd_en <= '0'; lcd_timer <= 5000; lcd_d <= lcd_data_buf(3 downto 0); state <= st_pulse_2;
                    when st_pulse_2 => lcd_en <= '1'; lcd_timer <= 50000; state <= st_wait;
                    when st_wait => lcd_en <= '0'; if lcd_data_buf = x"01" and lcd_rs_buf = '0' then lcd_timer <= 200000; else lcd_timer <= 10000; end if; state <= return_state;
                    when others => state <= st_power_on;
                end case;
            end if;
        end if;
    end process;
end Behavioral;