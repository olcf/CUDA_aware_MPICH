all: clean checkEnv
ifdef CRAY_PRGENVGNU
all: clean checkEnv setFlags direct_c
endif
ifdef CRAY_PRGENVPGI
all: clean checkEnv setFlags direct_f direct_acc_c direct_acc_f
endif
ifdef CRAY_PRGENVCRAY
all: clean checkEnv setFlags direct_acc_c direct_acc_f
endif

.PHONY:	checkEnv setFlags clean

checkEnv:
ifdef HMPP_BIN_PATH
        $(error CapsMC does not fully support CUDA enabled MPICH at this time)
endif
ifdef CRAY_PRGENVCRAY
    ifndef CRAY_ACCEL_TARGET
        $(error craype-accel-nvidia35 is required for PrgEnv-cray)
    endif
endif
ifndef CRAY_CUDATOOLKIT_VERSION
        $(error cudatoolkit module not loaded)
endif

setFlags:
ifdef CRAY_PRGENVGNU
        CFLAGS = -lcudart
endif
ifdef CRAY_PRGENVPGI
        CFLAGS = -acc -lcudart
        FFLAGS = -acc -lcudart
endif
ifdef CRAY_PRGENVCRAY
        CFLAGS = -hpragma=acc
        FFLAGS = -hacc
endif

direct_c: direct.cpp
	mkdir -p bin
	CC $(CFLAGS) -o bin/direct_c direct.cpp
direct_f: direct.cuf
	mkdir -p bin
	ftn -o bin/direct_f direct.cuf
direct_acc_c: direct_acc.c
	mkdir -p bin
	cc $(CFLAGS) -o bin/direct_acc_c direct_acc.c
direct_acc_f: direct_acc.f90
	mkdir -p bin
	ftn $(FFLAGS) -o bin/direct_acc_f direct_acc.f90

clean:
	rm -f *.o
	rm -f *.mod
	rm -rf bin
