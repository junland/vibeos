#!/bin/bash
# Perl XML Parser Step - Build and install Perl XML::Parser module in chroot

PERL_XML_PARSER_VER="2.47"

step_chroot_perl_xml_parser() {
	extract_file "${SOURCES_DIR}/XML-Parser-${PERL_XML_PARSER_VER}.tar.gz" "${WORK_DIR}/XML-Parser-${PERL_XML_PARSER_VER}"

	cd "${WORK_DIR}/XML-Parser-${PERL_XML_PARSER_VER}"

	msg "Building Perl XML::Parser module..."

	perl Makefile.PL

	make

	msg "Checking Perl XML::Parser module..."

	make test

	msg "Installing Perl XML::Parser module..."

	make install

	clean_dir ${WORK_DIR}
}