# -*- Makefile -*-
################################################################################
#
#  Author: Andy Rushton
#  Copyright: (c) Andy Rushton, 1999-2009
#  License:   BSD License, see license.txt
#
#  Generic makefile for building whole projects with the Gnu tools
#  For usage information see readme.txt
#
################################################################################

################################################################################
# Configure make to this platform
# New platforms should be added as required by adding more ifneq blocks
# The uname command usually gives a string like CYGWIN_NT-5.0 and I convert it to a simpler form like CYGWIN
# The rule is that every OS should map onto a different PLATFORM,
# furthermore, every OS type/version that needs a separate build should map onto a different BUILD,
# but OS versions that are binary-compatible with each other should map onto the same BUILD
#  - PLATFORM is the coarse-grain platform name used as a compiler directive
#  - BUILD is the fine-grain name used to differentiate between non-compatible objects
#  - VARIANT is the kind of build - release/debug etc
# I incorporate the CPU type into the name for OSs that are ported to many platforms

OS     := $(shell uname -s)

# on most platforms "uname -m" gives the CPU name
# However, see below for situations where this is overridden
CPU    := $(shell uname -m)

# Windows builds

# MinGW build on Windows
ifneq ($(findstring MINGW,$(OS)),)
PLATFORM  := MINGW
WINDOWS := on
endif

# Cygwin build on Windows
# if CYGMING=on then do native Windows build with Cygwin gcc
# else do Cygwin's Unix-emulation build with gcc
ifneq ($(findstring CYGWIN,$(OS)),)
ifeq ($(CYGMING),on)
PLATFORM  := CYGMING
WINDOWS := on
else
PLATFORM  := CYGWIN
UNIX := on
endif
endif

# Unix builds

# Build on Linux
ifneq ($(findstring Linux,$(OS)),)
PLATFORM  := LINUX
UNIX := on
endif

# Build on various flavours of BSD
ifneq ($(findstring FreeBSD,$(OS)),)
PLATFORM  := FREEBSD
UNIX := on
endif
ifneq ($(findstring OpenBSD,$(OS)),)
PLATFORM  := OPENBSD
UNIX := on
endif
ifneq ($(findstring NetBSD,$(OS)),)
PLATFORM  := NETBSD
UNIX := on
endif

# Build on Solaris - which identifies as SunOS
# Note: If I ever need to support SunOS 4 or earlier I'll have to differentiate between them somehow
ifneq ($(findstring SunOS,$(OS)),)
PLATFORM  := SOLARIS
UNIX := on
endif

# Build on MacOS-X which identifies as Darwin
# Should this be identified as Unix?
ifneq ($(findstring Darwin,$(OS)),)
PLATFORM  := MACOS
CPU    := $(shell uname -p)
endif

# test for undefined platform
ifeq ($(PLATFORM),)
$(error you need to configure the make system for platform $(OS))
endif

BUILD := $(PLATFORM)-$(CPU)

################################################################################
# setup variations in default compiler flags

ifeq ($(PLATFORM),CYGMING)
# the native Windows variant of the Cygwin compiler (i.e. the Cygming option)
# This uses the Cygwin compiler but links with the MS C run-time so that it doesn't use the Cygwin DLL
CFLAGS    += -mno-cygwin
CXXFLAGS  += -mno-cygwin
LDFLAGS   += -mno-cygwin
endif

ifeq ($(PLATFORM),SOLARIS)
# have to explicitly pull in the socket library
LOADLIBES += -lsocket
endif

ifeq ($(PLATFORM),NETBSD)
# have to explicitly state that the maths library should be included
LOADLIBES += -lm
endif

ifeq ($(BUILD),LINUX-alpha)
# enable IEEE-standard floating point
CPPFLAGS += -mieee
endif

ifeq ($(PLATFORM),CYGMING)
# need to explicitly add the Windows sockets 2 library
LOADLIBES += -lWs2_32
endif

ifeq ($(PLATFORM),CYGWIN)
# need to explicitly add the Windows sockets 2 library
LDFLAGS += -Wl,--enable-auto-import
endif

ifeq ($(PLATFORM),MINGW)
# need to explicitly add the Windows sockets 2 library
LOADLIBES += -lWs2_32
endif

################################################################################
# Configure build variant
# there are three different build variants:
#   debug - for internal development (default)
#   release - for shipping to customers (switched on by environment variable RELEASE=on)
#   gprof - for performance profiling (switched on by environment variable GPROF=on)

# common options for all variant builds for compile/link
CPPFLAGS  += -I. -D$(PLATFORM)
CFLAGS    += -funsigned-char -Wall -ansi
CXXFLAGS  += -ftemplate-depth-50 -funsigned-char -Wall
LDFLAGS   +=
LOADLIBES += -lstdc++

ifeq ($(RELEASE),on)
# release variant
CPPFLAGS += -DNDEBUG
CFLAGS   += -O3
CXXFLAGS += -O3
LDFLAGS  += -s
VARIANT  := release
else # RELEASE
ifeq ($(GPROF),on)
# gprof variant
CPPFLAGS += -DNDEBUG
CFLAGS   += -O3 -pg
CXXFLAGS += -O3 -pg
LDFLAGS  += -pg
VARIANT  := gprof
else # GPROF
# debug variant
CPPFLAGS +=
CFLAGS   += -g
CXXFLAGS += -g
LDFLAGS  +=
VARIANT  := debug
endif # GPROF
endif # RELEASE

################################################################################
# define the name of the subdirectory so that different builds have different subdirectories

SUBDIR := $(BUILD)-$(VARIANT)

################################################################################
# Unicode support
# use the option UNICODE=on to enable Unicode support
# this defines the pre-processor directives that switch on Unicode support in the headers
# Some libraries require directive UNICODE and others require _UNICODE, so define both
# Notes:
# - MinGW does not support wide I/O streams
# - Cygwin does not support wide strings or streams

ifeq ($(UNICODE),on)
CPPFLAGS += -DUNICODE -D_UNICODE
endif

################################################################################
# Resource compiler - make this Windows only

ifeq ($(WINDOWS),on)
RC := "windres"
RCFLAGS =
endif

################################################################################
# verbose option causes compiler/linker to be verbose

ifeq ($(VERBOSE),on)
# the native Windows variant of the Cygwin compiler (i.e. the Cygming option)
# This uses the Cygwin compiler but links with the MS C run-time so that it doesn't use the Cygwin DLL
CFLAGS    += -v
CXXFLAGS  += -v
LDFLAGS   += -v
RCFLAGS   += -v
endif

################################################################################
# now start generating the build structure

# function for determining the library name from the directory
# the library name is the containing directory 
# but if the containing directory is "source" (actually if it contains "source"), then the level above is used
library_name = $(if $(findstring source,$(notdir $(1))),$(notdir $(shell dirname $(1))),$(notdir $(1)))
# function for generating the archive name from the library name
archive_name = $(patsubst %,lib%.a,$(1))
# function for generating the subpath of an archive from the library name
archive_subpath = $(addprefix $(SUBDIR)/,$(call archive_name,$(1)))
# function for generating the full path to the archive from the library path
archive_path = $(addprefix $(1)/,$(call archive_subpath,$(call library_name,$(1))))
# function for determining whether a library has an archive or is a header-only library
# this returns the Makefile path if present and an empty string if not - so can be used in an if statement
archive_present = $(wildcard $(addsuffix /Makefile,$(1)))
# function for deciding whether to include a library - returns the library path if true, empty string if not
archive_library = $(if $(call archive_present,$(1)),$(1),)

# this adapts the make to find all .cpp files so they can be compiled as C++ files
CPP_SOURCES := $(wildcard *.cpp)
CPP_OBJECTS := $(patsubst %.cpp,$(SUBDIR)/%.o,$(CPP_SOURCES))

# this adapts the make to find all .c files so they can be compiled as C files
C_SOURCES := $(wildcard *.c)
C_OBJECTS += $(patsubst %.c,$(SUBDIR)/%.o,$(C_SOURCES))

ifeq ($(WINDOWS),on)
# this adapts the make to find all .rc files so they can be compiled as resource files
RC_SOURCES := $(wildcard *.rc)
RC_OBJECTS += $(patsubst %.rc,$(SUBDIR)/%_rc.o,$(RC_SOURCES))
endif

# the set of objects is a set of one .o file for each C or C++ file, stored in the build-specific subdirectory
OBJECTS := $(RC_OBJECTS) $(C_OBJECTS) $(CPP_OBJECTS)
# get the name of the library containing the code from this directory
LIBNAME := $(call library_name,$(shell pwd))

# the object library name is the library name with common conventions for library files applied
# don't generate a library if there are no object files to generate
LIBRARY  := $(call archive_subpath,$(LIBNAME))
ifeq ($(strip $(OBJECTS)),)
LIBRARY :=
endif

# the set of include directories is the set of libraries
INCLUDES  := $(addprefix -I,$(LIBRARIES))

# the set of link libraries - use the library list and find the name and location of each library archive
# exclude those which do not have a Makefile because those are header-only libraries
ARCHIVE_LIBRARIES := $(foreach lib,$(LIBRARIES),$(call archive_library,$(lib)))
ARCHIVES := $(foreach lib,$(ARCHIVE_LIBRARIES),$(call archive_path,$(lib)))

################################################################################
# Now implement the make rules

.PHONY: all clean tidy vcproject FORCE

all:: $(LIBRARY) $(ARCHIVE_LIBRARIES) $(IMAGE)

# Compilation Rules
# Also generate a dependency (.d) file. Dependency files are included in the make to detect out of date object files
# Note: gcc version 2.96 onwards put the .d files in the same place as the object files (correct)
#       earlier versions put the .d files in the current directory with the assumption that the object was there (wrong)
#       I no longer support those older versions

# the rule for compiling a C++ source file

$(SUBDIR)/%.o: %.cpp
	@echo "$(LIBNAME):$(SUBDIR): C++ compiling $<"
	@mkdir -p $(SUBDIR)
	@$(CXX) -x c++ -c -MMD $(CPPFLAGS) $(CXXFLAGS) $(INCLUDES) $< -o $@

# the rule for compiling a C source file

$(SUBDIR)/%.o: %.c
	@echo "$(LIBNAME):$(SUBDIR): C compiling $<"
	@mkdir -p $(SUBDIR)
	@$(CC) -x c -c -MMD $(CPPFLAGS) $(CFLAGS) $(INCLUDES) $< -o $@

ifeq ($(WINDOWS),on)
# the rule for compiling a resource file
# Note: add _rc suffix to name because I tend to name the resource file the same as the main C++ source file

$(SUBDIR)/%_rc.o: %.rc
	@echo "$(LIBNAME):$(SUBDIR): RC compiling $<"
	@mkdir -p $(SUBDIR)
	@$(RC) $(RCFLAGS) $< -o $@
endif

# Detect that a file is out of date with respect to its headers by including
# make rules generated during the last compilation of the file.
# Note: if a header file is deleted or moved then you can get an error since
# Make tries to find a rule to recreate that file. The solution is to delete
# the object library subdirectory (make clean) and do a clean build
-include $(SUBDIR)/*.d

# the rule for making an object library out of object files

$(LIBRARY): $(OBJECTS)
	@echo "$(LIBNAME):$(SUBDIR): Updating library $@"
	@$(AR) cru $(LIBRARY) $(OBJECTS)
ifeq ($(PLATFORM),MACOS)
	@ranlib $(LIBRARY)
endif

# The library dependencies are only built and the image is only linked if the IMAGE variable is defined
# only update other libraries if we are linking since just building an object library doesn't need the
# dependency libraries to be up to date

ifneq ($(IMAGE),)

# the rule for building the library dependencies unconditionally runs a recursive Make

$(ARCHIVE_LIBRARIES): FORCE
	@$(MAKE) -C $@

# the rule for linking an image

$(IMAGE): $(LIBRARY) $(ARCHIVES)
	@echo "$(LIBNAME):$(SUBDIR): Linking $(IMAGE)"
	@for l in $(LIBRARY) $(ARCHIVES); do echo "$(LIBNAME):$(SUBDIR):   using $$l"; done
	@mkdir -p $(dir $(IMAGE))
	@$(CXX) $(LDFLAGS) $^ $(LOADLIBES) -o $(IMAGE)

endif

tidy:
	@if [ -d "$(SUBDIR)" ]; then echo "$(LIBNAME): Tidy: deleting $(SUBDIR)"; rm -rf "$(SUBDIR)"; fi
	@/usr/bin/find . -name '*.tmp' -exec echo "$(LIBNAME): Tidy: deleting " {} \; -exec rm {} \;

clean: tidy
	@if [ -f "$(IMAGE).exe" ]; then echo "$(LIBNAME): Clean: deleting $(IMAGE)"; rm -f "$(IMAGE).exe"; fi
	@if [ -f "$(IMAGE)" ]; then echo "$(LIBNAME): Clean: deleting $(IMAGE)"; rm -f "$(IMAGE)"; fi

vcproject:
ifneq ($(IMAGE),)
	vcproject -exec $(addprefix -include ,$(LIBRARIES))
else
	vcproject $(addprefix -include ,$(LIBRARIES))
endif
