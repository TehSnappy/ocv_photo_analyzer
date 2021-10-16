# Variables to override
#
# CC            C compiler
# CROSSCOMPILE	crosscompiler prefix, if any
# CFLAGS	compiler flags for compiling all C files
# ERL_CFLAGS	additional compiler flags for files using Erlang header files
# ERL_EI_LIBDIR path to libei.a
# LDFLAGS	linker flags for linking all binaries
# ERL_LDFLAGS	additional linker flags for projects referencing Erlang libraries

LDFLAGS +=  -I"/usr/local/lib64/"
CFLAGS ?= -O2 -Wall -Wextra -Wno-unused-parameter
CFLAGS += -std=c++11 -D_GNU_SOURCE
CC ?= $(CROSSCOMPILER)gcc

#CFLAGS += -DDEBUG

SRC=$(wildcard src/*.cpp)


# -lrt is needed for clock_gettime() on linux with glibc before version 2.17
# (for example raspbian wheezy)
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
  LDFLAGS += -lrt
endif

CFLAGS += -I " /usr/local/lib64/" -I"/usr/local/include/" -I"/usr/local/include/opencv2/" -I"/usr/local/opt/opencv@4/include/opencv4" -I"/usr/local/include/opencv4/"
ERL_ROOT_DIR = $(ERLHOME)

# Look for the EI library and header files
# For crosscompiled builds, ERL_EI_INCLUDE_DIR and ERL_EI_LIBDIR must be
# passed into the Makefile.
ifeq ($(ERL_EI_INCLUDE_DIR),)
ERL_ROOT_DIR = $(shell erl -eval "io:format(\"~s~n\", [code:root_dir()])" -s init stop -noshell)
ifeq ($(ERL_ROOT_DIR),)
   $(error Could not find the Erlang installation. Check to see that 'erl' is in your PATH)
endif
ERL_EI_INCLUDE_DIR = "$(ERL_ROOT_DIR)/usr/include"
ERL_EI_LIBDIR = "$(ERL_ROOT_DIR)/usr/lib"
endif

# Set Erlang-specific compile and linker flags
# ERL_CFLAGS ?= -I$(ERL_EI_INCLUDE_DIR) -L$(/usr/lib)
ERL_CFLAGS ?= -I$(ERL_EI_INCLUDE_DIR)
ERL_LDFLAGS ?= -L$(ERL_EI_LIBDIR) -lei 

ERL_LDFLAGS += -lc++
ERL_CFLAGS += -I$(/usr/local/lib/erlang/usr/include)


# If compiling on OSX and not crosscompiling, include CoreFoundation and IOKit
ifeq ($(CROSSCOMPILE),)
ifeq ($(shell uname),Darwin)
LDFLAGS += -framework CoreFoundation -framework IOKit
endif
endif

LIBS_opencv = -lopencv_core -lopencv_core.4.5 -lopencv_highgui -lopencv_highgui.4.5 -lopencv_imgproc -lopencv_video -lopencv_objdetect -lopencv_imgproc -lopencv_imgcodecs



OBJ=$(SRC:.cpp=.o)

.PHONY: all clean

all: src priv priv/analyzer
				
%.o: %.cpp
	$(CC) -c $(ERL_CFLAGS) $(CFLAGS) -o $@ $<

priv:
	mkdir -p priv

priv/analyzer: $(OBJ)
	$(CC) $^ $(ERL_LDFLAGS) $(LDFLAGS) -o $@ $(LIBS_opencv)

clean:
	rm -f priv/analyzer$(EXEEXT) src/*.o src/ei_copy/*.o




