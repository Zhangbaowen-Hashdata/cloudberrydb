#-------------------------------------------------------------------------
#
# Makefile--
#    Makefile for storage/file
#
# IDENTIFICATION
#    src/backend/storage/file/Makefile
#
#-------------------------------------------------------------------------

subdir = src/backend/storage/file
top_builddir = ../../../..
include $(top_builddir)/src/Makefile.global

OBJS = \
	buffile.o \
	copydir.o \
	fd.o \
	reinit.o \
	sharedfileset.o \
	ufile.o

OBJS += execute_pipe.o gp_compress.o

include $(top_srcdir)/src/backend/common.mk
