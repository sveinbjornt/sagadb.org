#!/usr/bin/perl
#
# xml2txt - 
#
# Convert Saga Database XML markup to plain text
# Defaults to creating the files in same dir as XML
# Specify folder as last argument if you wish
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
use SagaDB::XML;
use SagaDB::Util;
use File::Basename;

# Need at least one argument
if (scalar(@ARGV) < 1)
{
    print STDERR "Not enough arguments.\nxml2txt.pl src1 ... [dstfolder]";
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

# Iterate through each file, convert from XML to plain text
foreach my $file(@ARGV)
{
    my $xmlfile = $file;
    
    if (! -e $xmlfile)
    {
        warn("File does not exist, skipping: $xmlfile\n");
        next;
    }
    
    if ($xmlfile !~ /\.xml$/)
    {
        warn("Not an XML file, skipping: $xmlfile\n");
        next;
    }
    
    # Create out file name
    my $outfile = $xmlfile;
    $outfile =~ s/\.xml$/\.txt/i;
    
    if (defined($folder))
    {
        my($fn, $directory) = fileparse($outfile);
        $outfile = $folder . $fn;
    }
    
    # Read data from file
    my $xml_data = ReadFile($xmlfile);
    
    my $sdbxml = new SagaDBXML($xml_data);
        
    $sdbxml->WritePlainTextRepresentationToFile($outfile);
}


