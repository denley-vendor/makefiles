################################################################################
#
#  Author: Andy Rushton
#  Copyright: (c) Andy Rushton, 2007-2009
#  License:   BSD License, see license.txt
#
#  Generic makefile extensions for building wxWidgets projects with the Gnu tools
#  include this after the gcc.mak makefile
#  Uses the wx-config script to get the specific details for this installation.
#  For usage information see readme.txt
#
################################################################################

ifeq ($(GPROF),on)
# gprof variant
$(error "wxWidgets doesn't support a profiling build")
endif

ifeq ($(UNICODE),on)
UNICODE_FLAG := --unicode=yes
else
UNICODE_FLAG := --unicode=no
endif

ifeq ($(RELEASE),on)
DEBUG_FLAG := --debug=no
else
DEBUG_FLAG := --debug=yes
endif

CXXFLAGS += `wx-config $(DEBUG_FLAG) $(UNICODE_FLAG) --cxxflags`
LOADLIBES += `wx-config $(DEBUG_FLAG) $(UNICODE_FLAG) --libs`
RC := `wx-config $(DEBUG_FLAG) $(UNICODE_FLAG) --rescomp`

ifeq ($(PLATFORM),MINGW)
# the mingw32 library maps the gcc main onto the Windows WinMain - so seed the link with this file
# also explicitly link in resource code otherwise the linker ignores it
LDFLAGS += -lmingw32 $(RC_OBJECTS)
endif
