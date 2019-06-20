UNAMEA := $(shell uname -a)
COND_LINUX := $(if $(findstring Linux,$(UNAMEA)),1)

check-filter:
ifeq ($(COND_LINUX),1)
	bats ob-filter-licenses.bats
else
	echo "ob-list-licenses not supported on mac/windows, sorry"
endif

check-parse:
ifeq ($(COND_LINUX),1)
	bats ob-parse-licenses.bats
else
	echo "ob-list-licenses not supported on mac/windows, sorry"
endif
