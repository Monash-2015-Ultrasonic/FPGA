onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /coef_reload_tb/clk
add wave -noupdate -format Logic /coef_reload_tb/reset_n
add wave -noupdate -format Logic /coef_reload_tb/start
add wave -noupdate -format Logic /coef_reload_tb/coef_set
add wave -noupdate -format Logic /coef_reload_tb/sink_ready
add wave -noupdate -format Literal /coef_reload_tb/sink_error
add wave -noupdate -format Logic /coef_reload_tb/sink_valid
add wave -noupdate -format Literal -radix decimal /coef_reload_tb/sink_data
add wave -noupdate -format Logic /coef_reload_tb/source_ready
add wave -noupdate -format Logic /coef_reload_tb/source_valid
add wave -noupdate -format Literal -radix decimal /coef_reload_tb/source_data
add wave -noupdate -format Literal /coef_reload_tb/source_error
add wave -noupdate -format Analog-Step -radix decimal -scale 0.001 /coef_reload_tb/source_data
add wave -noupdate -divider {New Divider}
add wave -noupdate -format Logic /coef_reload_tb/coef_we
add wave -noupdate -format Literal -radix decimal /coef_reload_tb/coef_in
add wave -noupdate -format Logic /coef_reload_tb/coef_set_reload
add wave -noupdate -format Analog-Step -scale 0.001 /coef_reload_tb/coef_in
add wave -noupdate -divider {New Divider}
add wave -noupdate -format Logic /coef_reload_tb/coef_we
add wave -noupdate -format Literal /coef_reload_tb/coef_in
add wave -noupdate -format Literal /coef_reload_tb/din_x
add wave -noupdate -format Literal /coef_reload_tb/din_int
add wave -noupdate -format Literal /coef_reload_tb/coef_x
add wave -noupdate -format Literal /coef_reload_tb/coef_int
add wave -noupdate -format Literal /coef_reload_tb/DUT/ast_sink_data
add wave -noupdate -format Literal /coef_reload_tb/DUT/ast_sink_error
add wave -noupdate -format Logic /coef_reload_tb/DUT/ast_sink_ready
add wave -noupdate -format Logic /coef_reload_tb/DUT/ast_sink_valid
add wave -noupdate -format Literal /coef_reload_tb/DUT/ast_source_data
add wave -noupdate -format Literal /coef_reload_tb/DUT/ast_source_error
add wave -noupdate -format Logic /coef_reload_tb/DUT/ast_source_ready
add wave -noupdate -format Logic /coef_reload_tb/DUT/ast_source_valid
add wave -noupdate -format Logic /coef_reload_tb/DUT/clk
add wave -noupdate -format Literal /coef_reload_tb/DUT/coef_in
add wave -noupdate -format Logic /coef_reload_tb/DUT/coef_we
add wave -noupdate -format Logic /coef_reload_tb/DUT/reset_n
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
configure wave -namecolwidth 247
configure wave -valuecolwidth 104
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
update
WaveRestoreZoom {0 ps} {5250 ns}
