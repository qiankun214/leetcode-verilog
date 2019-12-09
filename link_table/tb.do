vsim -voptargs="+acc" work.tb 

add wave -position end  sim:/tb/ut/u_link/clk
add wave -position end  sim:/tb/ut/u_link/rst_n
add wave -position end  sim:/tb/ut/u_link/order_valid
add wave -position end  sim:/tb/ut/u_link/order_busy
add wave -position end  sim:/tb/ut/u_link/ram_addr
add wave -position end  sim:/tb/ut/u_link/ram_read_data
add wave -position end  sim:/tb/ut/u_link/ram_write_req
add wave -position end  sim:/tb/ut/u_link/ram_write_data
add wave -position end  sim:/tb/ut/u_link/mode
add wave -position end  sim:/tb/ut/u_link/next_mode
add wave -position end  sim:/tb/ut/u_link/link_count
add wave -position end  sim:/tb/ut/u_link/this_node_num
add wave -position end  sim:/tb/ut/u_link/rewr_start_count
add wave -position end  sim:/tb/ut/u_link/rewr_count
add wave -position end  sim:/tb/ut/u_link/last_point_addr
add wave -position end  sim:/tb/ut/u_link/this_point_addr
add wave -position end  sim:/tb/ut/dout_valid
add wave -position end  sim:/tb/ut/dout_busy
add wave -position end  sim:/tb/ut/dout_data