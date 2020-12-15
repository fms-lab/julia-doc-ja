JULIAHOME := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
include $(JULIAHOME)/Make.inc

docs:
	@$(MAKE) $(QUIET_MAKE) -C $(BUILDROOT)/doc JULIA_EXECUTABLE='$(call spawn,$(JULIA_EXECUTABLE_$(JULIA_BUILD_MODE))) --\
startup-file=no'

clean: | $(CLEAN_TARGETS)
	@-$(MAKE) -C $(BUILDROOT)/doc clean
