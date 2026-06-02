ifeq ($(OS),Windows_NT)
    UNAME_S := $(shell uname -s 2>/dev/null || echo "")
    ifneq ($(findstring MINGW,$(UNAME_S)),)
        ifdef MSYSTEM
            PLATFORM := gitbash_msystem
        else
            PLATFORM := gitbash_no_msystem
        endif
    endif
endif
all:
	@echo PLATFORM=$(PLATFORM)
