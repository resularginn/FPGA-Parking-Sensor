## Clock
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## --- TEK BUTON ---
# L3 Pini: Tek Kontrol Butonu
set_property PACKAGE_PIN L3 [get_ports btn_control]
set_property IOSTANDARD LVCMOS33 [get_ports btn_control]
set_property PULLDOWN true [get_ports btn_control]

## BASYS 3 DAH?L? 7-SEGMENT P?NLER?
set_property PACKAGE_PIN W7 [get_ports {seg[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[0]}]
set_property PACKAGE_PIN W6 [get_ports {seg[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[1]}]
set_property PACKAGE_PIN U8 [get_ports {seg[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[2]}]
set_property PACKAGE_PIN V8 [get_ports {seg[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[3]}]
set_property PACKAGE_PIN U5 [get_ports {seg[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[4]}]
set_property PACKAGE_PIN V5 [get_ports {seg[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[5]}]
set_property PACKAGE_PIN U7 [get_ports {seg[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[6]}]
# Nokta (DP)
set_property PACKAGE_PIN V7 [get_ports dp]
set_property IOSTANDARD LVCMOS33 [get_ports dp]

# Anotlar
set_property PACKAGE_PIN U2 [get_ports {an[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[0]}]
set_property PACKAGE_PIN U4 [get_ports {an[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[1]}]
set_property PACKAGE_PIN V4 [get_ports {an[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[2]}]
set_property PACKAGE_PIN W4 [get_ports {an[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[3]}]

## Debug LED'leri (Durumu görmek için)
set_property PACKAGE_PIN U16 [get_ports led_state_0]
set_property IOSTANDARD LVCMOS33 [get_ports led_state_0]
set_property PACKAGE_PIN E19 [get_ports led_state_1]
set_property IOSTANDARD LVCMOS33 [get_ports led_state_1]

## --- PMOD JA (Sensör, Buzzer) ---
set_property PACKAGE_PIN M1 [get_ports led_green]
set_property IOSTANDARD LVCMOS33 [get_ports led_green]
set_property PACKAGE_PIN K3 [get_ports led_red]
set_property IOSTANDARD LVCMOS33 [get_ports led_red]
set_property PACKAGE_PIN M3 [get_ports led_yellow]
set_property IOSTANDARD LVCMOS33 [get_ports led_yellow]
set_property PACKAGE_PIN P18 [get_ports echo]
set_property IOSTANDARD LVCMOS33 [get_ports echo]
set_property PACKAGE_PIN N17 [get_ports trig]
set_property IOSTANDARD LVCMOS33 [get_ports trig]
# Buzzer (PMOD JA - Üst sat?r 2. pin -> M2)
set_property PACKAGE_PIN M2 [get_ports buzzer]
set_property IOSTANDARD LVCMOS33 [get_ports buzzer]

## --- PMOD JB (LCD) ---
set_property PACKAGE_PIN J1 [get_ports lcd_rs]
set_property IOSTANDARD LVCMOS33 [get_ports lcd_rs]
set_property PACKAGE_PIN L2 [get_ports lcd_en]
set_property IOSTANDARD LVCMOS33 [get_ports lcd_en]
set_property PACKAGE_PIN J2 [get_ports {lcd_d[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_d[4]}]
set_property PACKAGE_PIN G2 [get_ports {lcd_d[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_d[5]}]
set_property PACKAGE_PIN H2 [get_ports {lcd_d[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_d[6]}]
set_property PACKAGE_PIN G3 [get_ports {lcd_d[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_d[7]}]