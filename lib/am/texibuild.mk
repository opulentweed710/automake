## automake - create Makefile.in from Makefile.am
## Copyright (C) 1994-2012 Free Software Foundation, Inc.

## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2, or (at your option)
## any later version.

## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.

## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.

TEXI2DVI = texi2dvi
TEXI2PDF = $(TEXI2DVI) --pdf --batch
DVIPS = dvips
MAKEINFOHTML = $(MAKEINFO) --html
AM_MAKEINFOHTMLFLAGS ?= $(AM_MAKEINFOFLAGS)

define am__texibuild_dvi_or_pdf
	$1$(am__ensure_target_dir_exists) && \
	TEXINPUTS="$(am__TEXINFO_TEX_DIR)$(PATH_SEPARATOR)$$TEXINPUTS" \
## Must set MAKEINFO like this so that version.texi will be found even
## if it is in srcdir.
	MAKEINFO='$(MAKEINFO) $(AM_MAKEINFOFLAGS) $(MAKEINFOFLAGS) \
	                      -I $(@D) -I $(srcdir)/$(@D)' \

## texi2dvi and  texi2pdf don't silence everything with -q, redirect
## to /dev/null instead.  We still want -q ($(AM_V_TEXI_QUIETOPTS))
## because it turns on batch mode.
## Use '--build-dir' so that TeX and Texinfo auxiliary files and build
## by-products are left in there, instead of cluttering the current
## directory (see automake bug#11146).  Use a different build-dir for
## each file (as well as distinct build-dirs for PDF and DVI files) to
## avoid hitting a Texinfo bug that could cause a low-probability racy
## failure when doing parallel builds; see:
## http://lists.gnu.org/archive/html/automake-patches/2012-06/msg00073.html
	$2 $(AM_V_TEXI_QUIETOPTS) --build-dir=$3 \
	   -o $@ $< $(AM_V_TEXI_DEVNULL_REDIRECT)
endef

define am__texibuild_info
	$(if $1,,@$(am__ensure_target_dir_exists))
## Back up the info files before running makeinfo. This is the cheapest
## way to ensure that
## 1) If the texinfo file shrinks (or if you start using --no-split),
##    you'll not be left with some dead info files lying around -- dead
##    files which would end up in the distribution.
## 2) If the texinfo file has some minor mistakes which cause makeinfo
##    to fail, the info files are not removed.  (They are needed by the
##    developer while he writes documentation.)
	$(AM_V_MAKEINFO)restore=: && backupdir=.am$$$$ && \
	$(if $1,am__cwd=`pwd` && cd $(srcdir) &&) \
	rm -rf $$backupdir && mkdir $$backupdir && \
## If makeinfo is not installed we must not backup the files so
## 'missing' can do its job and touch $@ if it exists.
	if ($(MAKEINFO) --version) >/dev/null 2>&1; then \
	  for f in $@ $@-[0-9] $@-[0-9][0-9]; do \
	    if test -f $$f; then mv $$f $$backupdir; restore=mv; else :; fi; \
	  done; \
	else :; fi && \
	$(if $(am__info_insrc),cd "$$am__cwd" &&) \
	if $(MAKEINFO) $(AM_MAKEINFOFLAGS) $(MAKEINFOFLAGS) \
	               -I $(@D) -I $(srcdir)/$(@D) -o $@ $<; \
	then \
	  rc=0; \
	  $(if $(am__info_insrc),cd $(srcdir);) \
	else \
	  rc=$$?; \
## Beware that backup info files might come from a subdirectory.
	  $(if $(am__info_insrc),cd $(srcdir) &&) \
	  $$restore $$backupdir/* $(@D); \
	fi; \
	rm -rf $$backupdir; exit $$rc
endef

define am__texibuild_html
	$(AM_V_MAKEINFO)$(am__ensure_target_dir_exists) \
## When --split (the default) is used, makeinfo will output a
## directory.  However it will not update the time stamp of a
## previously existing directory, and when the names of the nodes
## in the manual change, it may leave unused pages.  Our fix
## is to build under a temporary name, and replace the target on
## success.
	  && { test ! -d $(@:.html=.htp) || rm -rf $(@:.html=.htp); } \
	  || exit 1; \
	if $(MAKEINFOHTML) $(AM_MAKEINFOHTMLFLAGS) $(MAKEINFOFLAGS) \
	                    -I $(@D) -I $(srcdir)/$(@D) \
			    -o $(@:.html=.htp) $<; \
	then \
	  rm -rf $@; \
## Work around a bug in Texinfo 4.1 (-o foo.html outputs files in foo/
## instead of foo.html/).
	  if test ! -d $(@:.html=.htp) && test -d $(@:.html=); then \
	    mv $(@:.html=) $@; else mv $(@:.html=.htp) $@; fi; \
	else \
	  if test ! -d $(@:.html=.htp) && test -d $(@:.html=); then \
	    rm -rf $(@:.html=); else rm -Rf $(@:.html=.htp) $@; fi; \
	  exit 1; \
	fi
endef

%.info: %.texi
	$(call am__texibuild_info,$(am__info_insrc))
%.dvi: %.texi
	$(call am__texibuild_dvi_or_pdf,$(AM_V_TEXI2DVI),$(TEXI2DVI),$(@:.dvi=.t2d))
%.pdf: %.texi
	$(call am__texibuild_dvi_or_pdf,$(AM_V_TEXI2PDF),$(TEXI2PDF),$(@:.pdf=.t2p))
%.html: %.texi
	$(call am__texibuild_html)

## The way to make PostScript, for those who want it.
%.ps: %.dvi
	$(AM_V_DVIPS)TEXINPUTS="$(am__TEXINFO_TEX_DIR)$(PATH_SEPARATOR)$$TEXINPUTS" \
	$(DVIPS) $(AM_V_TEXI_QUIETOPTS) -o $@ $<