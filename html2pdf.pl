#!/usr/bin/perl
#
# html2pdf - Convert SagaDB HTML to PDF format
#
# Defaults to creating the files in same dir as HTML
# Optionally specify destination folder as last arg
#      
# NOTE:  Will only work on Mac OS X systems due to dependence on the pstopdf tool
#
#  Copyright (c) 2007, Icelandic Saga Database (Sveinbjorn Thordarson)
#  All rights reserved.
#  
#  BSD License
#  
#  Redistribution and use in source and binary forms, with or without modification, are 
#  permitted provided that the following conditions are met:
#  
#      * Redistributions of source code must retain the above copyright notice, 
#      this list of conditions and the following disclaimer.
#      * Redistributions in binary form must reproduce the above copyright notice, 
#      this list of conditions and the following disclaimer in the documentation 
#      and/or other materials provided with the distribution.
#      * Neither the name of the Icelandic Saga Database nor the names of its 
#      contributors may be used to endorse or promote products derived from this
#      software without specific prior written permission.
#  
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY 
#  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
#  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT 
#  SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
#  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
#  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
#  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
#  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
#  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

use strict;
use File::Basename;
use Encode::Guess;
use SagaDB::Util;
use Shell qw(cp);

my $html2ps = "html2ps/html2ps";
my $html2psConfig = "html2ps/sagadbconf";

# Need at least one argument
if (scalar(@ARGV) < 1)
{
	print STDERR "Not enough arguments.\nhtml2pdf.pl src1 ... [dstfolder]";
	exit(1);
}

# If last argument is a folder, it's the destination folder
my $lastarg = $ARGV[scalar(@ARGV)-1];
my $folder = undef;
if (-e $lastarg && ! -f $lastarg)
{
	$folder = $lastarg . "/";
	pop @ARGV;
}

# Iterate through each file, convert from XML format to XHTML
foreach my $file(@ARGV)
{
	my $htmlfile = $file;
	
	if ($htmlfile !~ /\.html$/)
	{
		warn("Not an HTML file, skipping: $htmlfile\n");
		next;
	}
	
	# Create out file name
	my $outfile = $htmlfile;
	$outfile =~ s/\.html$/\.pdf/i;
	
	if (defined($folder))
	{
		my($fn, $directory) = fileparse($outfile);
		$outfile = $fn;
		$outfile = $folder . $outfile;
	}
		
	print "$htmlfile --> $outfile\n";
	
	# OK, let's check the encoding of the HTML file
	#my $data = ReadFile($htmlfile);
	#my $decoder = guess_encoding($data, 'latin1');
    #die $decoder unless ref($decoder);
    #my $res = $decoder->decode($data);
    
    # Convert UTF-8 to ISO-8859-1 for PDF generation,
    # using iconv since html2ps can't handle UTF-8
    
    my $tmp = '/tmp/sagadb_tmp.html';
    my $out_tmp = '/tmp/sagadb_tmp_out.html';
	cp($htmlfile, $tmp);
	if (! -e $tmp) { die("Could not create temporary file '$tmp'"); }
	system("iconv -c -f UTF-8 -t ISO-8859-1 '$tmp' > '$out_tmp'");
    
	# Run through html2ps tool
	my $cmd = "/usr/bin/perl $html2ps -f $html2psConfig '$out_tmp' | ps2pdf - '$outfile'";
	#print "Running command '$cmd'\n";
	system($cmd);
	
	# Remove temp files
	rm($tmp, $out_tmp);
}


