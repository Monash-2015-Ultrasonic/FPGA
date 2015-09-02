
if {[file exist [project env]] > 0} {project close}
if {[file exist "coef_reload.mpf"] == 0} {
  project new . coef_reload
} else	{
project open coef_reload
}
if {[file exist work] ==0} 	{
  exec vlib work
  exec vmap work work}
        
vlog c:/altera/91/quartus//eda/sim_lib/220model.v
vlog c:/altera/91/quartus//eda/sim_lib/altera_mf.v
vlog c:/altera/91/quartus//eda/sim_lib/sgate.v
vlog coef_reload_tb.v
vlog fir91.vo

vsim coef_reload_tb
do wave.do
run 5000 ns;
