vsim -voptargs=+acc work.tb

add wave -position 0  sim:/tb/clk
add wave -position end  sim:/tb/ut/dut/ram_addr
add wave -position end  sim:/tb/ut/dut/ram_write_req
add wave -position end  sim:/tb/ut/dut/ram_write_data
add wave -position end  sim:/tb/ut/dut/ram_read_data
add wave -position end  sim:/tb/ut/dut/mode
add wave -position end  sim:/tb/ut/dut/next_mode

add wave -position end  sim:/tb/ut/dut/cycle_count
add wave -position end  sim:/tb/ut/dut/read_count

add wave -position end  sim:/tb/ut/dut/max_data
add wave -position end  sim:/tb/ut/dut/max_index
add wave -position end  sim:/tb/ut/dut/this_input
add wave -position end  sim:/tb/ut/dut/rewrite_data