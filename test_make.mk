HOME := C:\Users\runneradmin

HOME_DIR := $(subst \,/,$(HOME))

all:
	@echo $(HOME_DIR)
