GHDL=ghdl
WORKDIR=work
SRC_DIR=sources
VHDL_FILES=$(SRC_DIR)/defs_pkg.vhd \
            $(SRC_DIR)/add_round_key.vhd \
            $(SRC_DIR)/key_expansion.vhd \
            $(SRC_DIR)/mix_column.vhd \
            $(SRC_DIR)/shift_rows.vhd \
            $(SRC_DIR)/sub_bytes.vhd \
            $(SRC_DIR)/aes_enc.vhd \
            $(SRC_DIR)/aes_enc_top.vhd 

TEST_DIR=testbenches
TESTBENCHES=$(TEST_DIR)/tb_key_expansion.vhd\
			$(TEST_DIR)/tb_sub_bytes.vhd\
			$(TEST_DIR)/tb_shift_rows.vhd\
			$(TEST_DIR)/tb_mix_column.vhd\
			$(TEST_DIR)/tb_add_round_key.vhd\
			$(TEST_DIR)/tb_aes_enc.vhd\
			$(TEST_DIR)/tb_aes_enc_top.vhd\

			
TOP_ENTITY=tb_aes_enc_top

all: clean compile elaborate run show

compile:
	@echo "📦 Compiling VHDL files..."
	$(GHDL) -a --std=08 --workdir=$(WORKDIR) $(VHDL_FILES)
	$(GHDL) -a --std=08 --workdir=$(WORKDIR) $(TESTBENCHES)

elaborate:
	@echo "🔧 Elaborating $(TOP_ENTITY)..."
	$(GHDL) -e --std=08 --workdir=$(WORKDIR) $(TOP_ENTITY)

run:
	@echo "🚀 Running simulation..."
	$(GHDL) -r --workdir=$(WORKDIR) $(TOP_ENTITY) --vcd=$(WORKDIR)/$(TOP_ENTITY).vcd  --stop-time=2us

show:
	gtkwave $(WORKDIR)/$(TOP_ENTITY).vcd

clean:
	rm -rf $(WORKDIR)/*
