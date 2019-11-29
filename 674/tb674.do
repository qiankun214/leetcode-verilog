vsim -voptargs=+acc work.tb674
add wave -position end  sim:/tb674/ADDR_WIDTH
add wave -position end  sim:/tb674/DATA_WIDTH
add wave -position end  sim:/tb674/clk
add wave -position end  sim:/tb674/rst_n

add wave -position end  sim:/tb674/order_valid
add wave -position end  sim:/tb674/order_busy
add wave -position end  sim:/tb674/order_start
add wave -position end  sim:/tb674/order_len
add wave -position end  sim:/tb674/order_back

add wave -position end  sim:/tb674/ut/u_compute/mode
add wave -position end  sim:/tb674/ut/u_compute/addr_count
add wave -position end  sim:/tb674/ut/u_compute/this_data
add wave -position end  sim:/tb674/ut/u_compute/last_data
add wave -position end  sim:/tb674/ut/u_compute/this_len
add wave -position end  sim:/tb674/ut/u_compute/result

add wave -position end  sim:/tb674/ut/u_ram/addr
add wave -position end  sim:/tb674/ut/u_ram/din
add wave -position end  sim:/tb674/ut/u_ram/write_req
add wave -position end  sim:/tb674/ut/u_ram/dout

run -all