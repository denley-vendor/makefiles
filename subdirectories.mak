################################################################################
#
#  Author: Andy Rushton
#  Copyright: (c) Andy Rushton, 1999-2009
#  License:   BSD License, see license.txt
#
#  Generic makefile that simply finds all subdirectories containing Makefiles and recurses on them
#  include this in any Makefile where you want this behaviour
#  For usage information see readme.txt
#
################################################################################

all tidy clean vcproject::
	@for m in */Makefile; do $(MAKE) -C `dirname $$m` $@; done

