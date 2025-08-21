
TB_NAME  	?= tb
TESTNAME 	?= tb
RADIX       ?= hexadecimal
RTL_FILES := $(filter-out %_copy.v %_old.v, $(wildcard ../rtl/*.v))
LOCATE ?= ..
COV_DIR = cov
LOG_DIR = log
VCD_DIR = vcd
#=================

all: build run

all_wave: all wave

all_dec: all dec

# build: | $(VCD_DIR)
# 	if not exist .\$(TESTNAME).v copy ..\testcase\$(TESTNAME).v  .\$(TESTNAME).v
# 	if exist .\run_test.v del /q .\run_test.v
# 	rename  .\$(TESTNAME).v run_test.v
# 	iverilog -o ./$(VCD_DIR)/$(TB_NAME).vcd ../tb/$(TB_NAME).v $(RTL_FILES)

# run: | $(LOG_DIR)
# # 	if not exist ./$(LOG_DIR)/$(TESTNAME).log type nul > ./$(LOG_DIR)/$(TESTNAME).log
# 	vvp -l ./$(LOG_DIR)/$(TESTNAME).log ./$(VCD_DIR)/$(TB_NAME).vcd 

wave:
	gtkwave .\dump.vcd

dec:
	C:\Program Files\sigrok\PulseView\pulseview.exe --clean --settings ./sim/session.pvs --input-file ./sim/dump_dec.vcd 

all: build run

check:
	-@verilator --lint-only $(RTL_FILES)>./check.log 2>&1
	type .\check.log

build:
# 	if not exist .\$(TESTNAME).v copy ..\testcase\$(TESTNAME).v  .\$(TESTNAME).v
# 	if exist .\run_test.v del /q .\run_test.v
# 	rename  .\$(TESTNAME).v run_test.v

	vlib work
	vmap work work
	vlog ../tb/$(TB_NAME).v $(RTL_FILES)

run: | $(LOG_DIR)
	vsim -debugDB -L .\work -voptargs=+acc -assertdebug -c $(TB_NAME) -do "log -r /*;run -all;" -l .\log\$(TESTNAME).log

wave_ques:
	vsim -i -view ./vsim.wlf 
# 	-do "add wave vsim:${TB_NAME}; radix $(RADIX); Waveform Zoom Range 30" &


all_cov: build_cov run_cov gen_cov

build_cov:
# 	if not exist .\$(TESTNAME).v copy ..\testcase\$(TESTNAME).v  .\$(TESTNAME).v
# 	if exist .\run_test.v del /q .\run_test.v
# 	rename  .\$(TESTNAME).v run_test.v

	vlib work
	vmap work work
	vlog +cover=bcesft ../tb/$(TB_NAME).v $(RTL_FILES)

run_cov: | $(LOG_DIR) $(COV_DIR)
	vsim -voptargs="+cover=bcesft"  -coverage -l ./$(LOG_DIR)/$(TESTNAME).log -assertdebug -c $(TB_NAME) -do " coverage save -onexit ./$(COV_DIR)/$(TESTNAME).ucdb; log -r /*;run -all;"
	
gen_cov:
	vcover merge ./$(COV_DIR)/IP.ucdb ./$(COV_DIR)/$(TESTNAME).ucdb
	vcover report ./$(COV_DIR)/IP.ucdb -output ./$(COV_DIR)/summary_report.txt
	vcover report -zeros -details -code bcesft -annotate -All -codeAll ./$(COV_DIR)/IP.ucdb -output ./$(COV_DIR)/detail_report.txt
	if exist .\$(COV_DIR)\$(TESTNAME).ucdb del /q .\$(COV_DIR)\$(TESTNAME).ucdb

clean: 
# 	if exist .\vcd rmdir /s /q .\vcd
# 	if exist .\vcd\*.vcd del /q .\vcd\*.vcd
# 	if exist *.ini del /q *.ini
# 	if exist *.wlf del /q *.wlf
# 	if exist transcript del /q transcript
# 	if exist $(COV_DIR)\*.ucdb del /q $(COV_DIR)\*.ucdb
# 	if exist $(COV_DIR)\work rmdir /s /q $(COV_DIR)\work

clean: 
	if exist .\vcd rmdir /s /q .\vcd
	if exist .\wlf rmdir /s /q .\wlf
	if exist .\log rmdir /s /q .\log
	if exist .\work rmdir /s /q .\work
	if exist .\$(COV_DIR) rmdir /s /q .\$(COV_DIR)
	if exist *.ini del /q *.ini
	if exist *.wlf del /q *.wlf
	if exist *.dbg del /q *.dbg
	if exist *.log del /q *.log
	if exist transcript del /q transcript

$(COV_DIR):
	if not exist $(COV_DIR) mkdir $(COV_DIR)

$(LOG_DIR):
	if not exist $(LOG_DIR) mkdir $(LOG_DIR)

$(VCD_DIR):
	if not exist $(VCD_DIR) mkdir $(VCD_DIR)
