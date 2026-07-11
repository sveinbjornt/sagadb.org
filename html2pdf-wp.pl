#!/usr/bin/perl
#
# html2pdf-wp.pl - Convert SagaDB HTML to PDF using WeasyPrint.
#
# A UTF-8-native drop-in replacement for html2pdf.pl. Unlike the old
# html2ps + iconv + Ghostscript pipeline, WeasyPrint consumes the UTF-8
# XHTML directly, so no ISO-8859-1 transcoding happens and every glyph
# (þ ð æ ö ǫ œ, curly quotes, em dashes) renders faithfully. Styling is
# controlled by tpl/pdf.css using ordinary print CSS.
#
# Requires WeasyPrint on PATH (e.g. `brew install weasyprint`).
#
# Same command-line interface as html2pdf.pl:
#     html2pdf-wp.pl <input.html> <output.pdf>
#
#  Copyright (c) 2007 Icelandic Saga Database (Sveinbjorn Thordarson)
#  BSD License
#

use strict;
use warnings;

my $weasyprint = "weasyprint";      # expected on PATH
my $stylesheet = "tpl/pdf.css";     # print stylesheet (relative to repo root)

# Need at least two arguments
if (scalar(@ARGV) < 2)
{
    print STDERR "Not enough arguments.\nUsage: html2pdf-wp.pl <input.html> <output.pdf>\n";
    exit(1);
}

my $infile  = $ARGV[0];
my $outfile = $ARGV[1];

if ($infile !~ /\.html?$/)
{
    warn("Not an HTML file, skipping: $infile\n");
    exit(1);
}
if (! -e $infile)
{
    die("Input file '$infile' does not exist\n");
}

# Run WeasyPrint. Using the list form of system() avoids any shell
# quoting issues with paths that contain spaces or special characters.
my @cmd = ($weasyprint, $infile, $outfile, "-s", $stylesheet);
my $status = system(@cmd);

if ($status == -1)
{
    die("Failed to run '$weasyprint' - is WeasyPrint installed and on PATH? ($!)\n");
}
elsif ($status != 0)
{
    die("WeasyPrint failed (exit code " . ($status >> 8) . ") for '$infile'\n");
}
