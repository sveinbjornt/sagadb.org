#!/usr/bin/perl
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

package SagaDB::Util;

use strict;
use base "Exporter";
our @EXPORT = qw(ReadFile WriteFile HumanDateFromTimestamp GetDate);

sub ReadFile
{
    my $file = shift @_;
    
    open(FILE, $file) or die("Couldn't open file '$file' for reading");
    my $data;
    while (<FILE>)
    {
        $data .= $_;
    }
    close(FILE);
    return $data;
}

sub WriteFile
{
    my $file = shift @_;
    my $data = shift @_;
    
    #print "Writing file '$file'\n";
    open(FILE, "+>$file") or die("Couldn't open file '$file' for writing.");
    print FILE $data;
    close(FILE);
}

sub GetDate 
{
    my(@days)  = ('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday');
    my(@months) =    ('January', 'February', 'March', 'April', 'May', 'June','July', 'August', 'September', 'October', 'November', 'December');

    my($sec,$min,$hour,$mday,$mon,$year,$wday) = (gmtime(time))[0,1,2,3,4,5,6];
    my($thetime) = sprintf("%02d:%02d:%02d",$hour,$min,$sec);
    $year += 1900;

    my($longd) = "$days[$wday], $months[$mon] $mday, $year.";
    $mon++;
    
    if ($mday < 10)    {    $mday    = "0$mday";   }
    if ($mon < 10)    {    $mon     = "0$mon";       }
    if ($hour < 10) {    $hour    = "0$hour";   }
    if ($min < 10)  {    $min     = "0$min";       }
    if ($sec < 10)  {   $sec     = "0$sec";    }
        
    return ($longd, "$year-$mon-$mday-$hour-$min-$sec", "$mday.$mon.$year", $thetime, $year);
}

# sub HumanDateFromTimestamp
# {
#     my(@months) = ('January', 'February', 'March', 'April', 'May', 'June','July', 'August', 'September', 'October', 'November', 'December');
#     my(@days)   =   ('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday');
#     my($timestamp) = @_;
#     
#     if ($timestamp !~ m/\d\d\d\d-\d\d-\d\d-\d\d-\d\d-\d\d/) {   return "Not available"; }
#     
#     my($year,$month,$mday,$hour,$min,$sec) = split(/\-/, $timestamp);
#     my($human_date) = "$hour:$min:$sec $months[$month-1] $mday $year";
#     return $human_date;
# }

1;

__END__