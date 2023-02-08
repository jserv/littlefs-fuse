TARGET = lfs

OS := $(shell uname -s)

CC = cc
AR = ar
SIZE = size

SRC += littlefs/lfs.c littlefs/lfs_util.c
SRC += lfs_fuse.c lfs_fuse_bd.c
OBJ := $(SRC:.c=.o)
DEP := $(SRC:.c=.d)

ifdef DEBUG
override CFLAGS += -O0 -g3
else
override CFLAGS += -Os
endif
ifdef WORD
override CFLAGS += -m$(WORD)
endif
override CFLAGS += -I. -Ilittlefs
override CFLAGS += -std=c99 -Wall -pedantic
override CFLAGS += -D_FILE_OFFSET_BITS=64
override CFLAGS += -D_XOPEN_SOURCE=700
override CFLAGS += -DLFS_MIGRATE

ifeq ($(OS), Darwin)
override CFLAGS += -I /usr/local/include/osxfuse
override LFLAGS += -L /usr/local/lib
override LFLAGS += -losxfuse
else
override LFLAGS += -lfuse
endif

ifeq ($(OS), FreeBSD)
override CFLAGS += -I /usr/local/include
override CFLAGS += -D __BSD_VISIBLE
override LFLAGS += -L /usr/local/lib
endif

all: stamp-littlefs

stamp-littlefs:
	git clone https://github.com/littlefs-project/littlefs
	@test -f littlefs/lfs.c || (echo No littlefs found.; exit 1)
	@test -f littlefs/lfs_util.c || (echo Incomplete littlefs implementation.; exit 1)
	touch $@ littlefs
	$(MAKE) $(TARGET)

size: $(OBJ)
	$(SIZE) -t $^

-include $(DEP)

$(TARGET): $(OBJ)
	$(CC) $(CFLAGS) $^ $(LFLAGS) -o $@

%.a: $(OBJ)
	$(AR) rcs $@ $^

%.o: %.c
	$(CC) -c -MMD $(CFLAGS) $< -o $@

clean:
	rm -f $(TARGET)
	rm -f $(OBJ)
	rm -f $(DEP)

distclean: clean
	rm -rf littlefs
	rm -f stamp-littlefs
