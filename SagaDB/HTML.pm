#!/usr/bin/perl
#
#  Copyright (c) 2007 Icelandic Saga Database (Sveinbjorn Thordarson)
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

package SagaDB::HTML;

@ISA = qw ( SagaDB::XML );

use strict;
use SagaDB::Util;
use base "Exporter";
our @EXPORT = qw();

sub HTMLRepresentationFromTemplate
{
    my $self = shift @_;
    my $tpl = shift @_;
    my $header = shift @_;
    if ($header eq undef)
    {
        $header = "";
    }
    
    if (!defined($self->{metadata}))
    {
        $self->{metadata} = $self->ParseMetaData();
    }
    
    my $html = $self->HTMLRepresentation();
    
    my ($long_date, $iso_timestamp) = GetDate();
    my $tpl = ReadFile($tpl);
    $tpl =~ s/%%header%%/$header/gi;
    $tpl =~ s/%%content%%/$html/gi;
    $tpl =~ s/%%datecreated%%/$iso_timestamp/gi;
    $tpl =~ s/%%title%%/$self->{metadata}->{title}/gi;
    $tpl =~ s/%%basename%%/$self->{metadata}->{basename}/gi;

    return $tpl;
}

sub HTMLCitationRepresentationFromTemplate
{
    my $self = shift @_;
    my $tpl = shift @_;
    
    # Make sure to parse metadata
    if (!defined($self->{metadata}))
    {
        $self->{metadata} = $self->ParseMetaData();
    }
    my %metadata = %{$self->{metadata}};
    
    my $html_template = ReadFile($tpl) or die("Couldn't read template $tpl");

    # Replace all variables in template w. metadata info
    foreach my $key(sort(keys(%metadata)))
    {
        $html_template =~ s/%%$key%%/$metadata{$key}/gi;
    }

    return $html_template;
}

1;

__END__