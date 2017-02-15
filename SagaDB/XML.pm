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

package SagaDB::XML;

use strict;
use XML::Parser::Lite::Tree;
use Data::Dumper;
use SagaDB::Util;
use Encode qw(decode encode);

my %lang_chapters = (
                        "is" => "NUM. kafli",
                        "en" => "Chapter NUM",
                        "de" => "Kapitel NUM",
                        "fr" => "Chapitre NUM",
                        "da" => "Kapitel NUM",
                        "no" => "Kapittel NUM",
                        "se" => "Kapitel NUM",
                        "on" => "NUM. kafli"
                    );

my $xml_data = undef;
my $audio = 0;
my %metadata = undef;

##################### OBJECT METHODS ########################

sub new 
{
    my $class = shift;
    my $self = {    xml_data  => shift,
                    html => undef,
                    text => undef,
                    tree => undef,
                    metadata => undef,
                    audio => 0
                };
    bless $self, $class;
 
    $self->ParseXML($self->{xml_data});
       
    return $self;
}

sub ParseXML
{
    my $self = shift @_;
    $self->{tree} = XML::Parser::Lite::Tree::instance()->parse($self->{xml_data});
}

sub ParseMetaData
{
    my ($self) = shift @_;
        
    my @children = @{$self->{tree}->{children}[1]{children}};
    my @md;
    
    foreach my $child(@children)
    {
        if ($child->{name} eq 'metadata')
        {
            @md = @{$child->{children}};
        }
    }    
    
    my %metadata;
    foreach my $child(@md)
    {
        # We only read in elements in the metadata tag
        if ($child->{type} ne 'element'){ next;}
        
        my $value;
        my $key = $child->{name};
        
        my @children = @{$child->{children}};
        foreach (@children)
        {
            # Ignore any child tags
            if ($_->{type} ne 'text') { next; }
            
            $value = $_->{content};
        }
        
        $metadata{$key} = $value;
    }
    
    return \%metadata;
}

sub WriteHTMLRepresentationToFile
{
    my $self = shift @_;
    my $path = shift @_;
    my $audio = shift @_;
    
    my $html;
    
    if (!defined($self->{html}))
    {
        $self->{html} = $self->HTMLRepresentation();
    }
    
my $htmldoc =     <<"EOF";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="$self->{metadata}->{language_iso}">
<head>
    <title>$self->{metadata}->{title}</title>
    <meta http-equiv="Content-Type" content="application/xhtml+xml; charset=utf-8" />
    <meta name="copyright" content="This text is in the public domain." />
    <meta name="generator" content="SagaDB build mechanism" /> 
    <meta http-equiv="Content-Language" content="$self->{metadata}->{language_iso}" /> 
</head>
<body>

$self->{html}

</body>
</html>
EOF
    
    WriteFile($path, $htmldoc);
}

sub HTMLRepresentation
{
    my $self = shift @_;
    
    if (defined($self->{html}))
    {
        return $self->{html};
    }
    
    if (!defined($self->{tree})) { die("No XML tree"); }
    
    if (!defined($self->{metadata}))
    {
        $self->{metadata} = $self->ParseMetaData();
    }
        
    my @c = @{$self->{tree}->{children}[1]{children}};
        
    # Find the content node
    my $html;
    foreach my $child(@c)
    {
        if ($child->{name} eq 'content')
        {
            $html = $self->XMLContentToHTML($child->{children});
        }
    }
        
    my %metadata = %{$self->{metadata}};
    my $translation = TranslationNoteFromMetadata(\%metadata);
    
    # Add translation paragraph note
    if (defined($self->{metadata}{trans}))
    {
        $html = "<p class=\"translation_note\">$translation</p>\n\n$html";
    }
    
    $html = <<"EOF";
<h1>$metadata{title}</h1>
        
$html
EOF
    
    return $html;
}

sub WritePlainTextRepresentationToFile
{
    my $self = shift @_;
    my $path = shift @_;
    
    if (!defined($self->{text}))
    {
        $self->{text} = $self->PlainTextRepresentation();
    }
    
    WriteFile($path, $self->{text});
}

sub PlainTextRepresentation
{
    my $self = shift @_;
    
    if (defined($self->{text}))
    {
        return $self->{text};
    }
    
    if (!defined($self->{tree})) { die("No XML tree"); }
    
    if (!defined($self->{metadata}))
    {
        $self->{metadata} = $self->ParseMetaData();
    }
    
    my @c = @{$self->{tree}->{children}[1]{children}};
        
    # Find the content node
    my $text;
    foreach my $child(@c)
    {
        if ($child->{name} eq 'content')
        {
            $text = $self->XMLContentToPlainText($child->{children});
        }
    }
    
    my $translation = TranslationNoteFromMetadata($self->{metadata});
    
    $text = <<"EOF";

$self->{metadata}->{title}
$translation
    
$text
EOF
    
    return $text;
}

sub CreateEPUBAtPath
{
    my $self = shift @_;
    my $path = shift @_;
    
    use EBook::EPUB;

    # Create EPUB object
    my $epub = EBook::EPUB->new;

    # Set metadata: title/author/language/id
    
    my $decoded_title = decode('UTF-8', $self->{metadata}->{title});    
    $epub->add_title($decoded_title);
    $epub->add_author("Anonymous");
    $epub->add_contributor("Icelandic Saga Database", [fileas => "Icelandic Saga Database", role => "edt"]);
    $epub->add_identifier("http://sagadb.org/" . $self->{metadata}->{basename}, "url");

    # Add date of publication
    my $tmpdate = substr($self->{metadata}->{date_added},0,10);
    $epub->add_date($tmpdate, "publication");

    # Add date of translation
    if (defined($self->{metadata}->{trans_date}))
    {
        $epub->add_date($self->{metadata}->{trans_date}, "creation");
    }
    
    # Translator
    if (defined($self->{metadata}->{trans}))
    {
        my $decoded_translname = decode('UTF-8', $self->{metadata}->{trans});
        $epub->add_translator($decoded_translname);
    }

    # Rights, subject
    $epub->add_rights("This text is in the public domain");
    $epub->add_subject("Icelandic Saga");

    # Source
    if (defined($self->{metadata}->{source}))
    {
        $epub->add_source($self->{metadata}->{source});
    }
    
    my $chapter_dir = "/tmp/" . $self->{metadata}->{basename};
    my @chapter_files = @{$self->CreateXHTMLChaptersInDirectory($chapter_dir)};
    
    my $chapnum = 1;
    foreach my $chapterfile (@chapter_files)
    {
        my $chapter_id = $epub->copy_xhtml($chapterfile,  $chapnum . ".xhtml");

           my $navpoint = $epub->add_navpoint(
                  label       => "Chapter $chapnum",
                  id          => $chapter_id,
                  content     => $chapnum . ".xhtml",
                  play_order  => $chapnum # should always start with 1
          );
        $chapnum++;
    }
    
    # Generate ebook
    $epub->pack_zip($path);
    
    #system("rm -r '$chapter_dir'")
}

sub CreateChapterAudioFilesInDirectory
{
    my $self = shift @_;
    my $dir = shift @_;
    
    my $saycmd = '/usr/bin/say';
    my $lamecmd = '/usr/local/bin/lame';
    
    if (! -e $saycmd or ! -e $lamecmd)
    {
        warn("Cannot create audio files, tool '$saycmd' or '$lamecmd' missing from system.");
        return;
    }
    
    if (!defined($self->{tree})) { die("No XML tree"); }
    
    if (!defined($self->{metadata}))
    {
        $self->{metadata} = $self->ParseMetaData();
    }
    
    my @c = @{$self->{tree}->{children}[1]{children}};
    my @chapternodes;
    foreach my $child(@c)
    {
        if ($child->{name} eq 'content')
        {
            @chapternodes = @{$child->{children}};
        }
    }
    
    # Create array, each element is HTML for 1 chapter
    my @chapters;
    foreach my $child(@chapternodes)
    {
        if ($child->{name} eq 'chapter')
        {
            push(@chapters, $self->XMLContentToPlainText($child->{children}));
        }
    }
    
    # Create directory for all the chapter files
    mkdir($dir);
    
    my $chapnum = 1;
    my @files;
    foreach my $chapter (@chapters)
    {        
        my $outfile = $dir . '/' . $chapnum . '.aiff';
        my $mp3file = $dir . '/' . $chapnum . '.mp3';
        
        WriteFile('/tmp/smu.txt', $chapter);
        
        print "\t\tCreating AIFF file '$outfile'\n";
        system("/usr/bin/say -v Daniel -f /tmp/smu.txt -o '$outfile'");
        print "\t\tMP3 encoding to '$mp3file'\n";
        system("/usr/local/bin/lame --quiet '$outfile' '$mp3file'");
        print "\t\tUnlinking AIFF file\n";
        unlink($outfile);
        
        $chapnum++;
    }
    
}

sub CreateXHTMLChaptersInDirectory
{
    my $self = shift @_;
    my $dir = shift @_;
    
    if (!defined($self->{tree})) { die("No XML tree"); }
    
    if (!defined($self->{metadata}))
    {
        $self->{metadata} = $self->ParseMetaData();
    }
    
    my @c = @{$self->{tree}->{children}[1]{children}};
    my @chapternodes;
    foreach my $child(@c)
    {
        if ($child->{name} eq 'content')
        {
            @chapternodes = @{$child->{children}};
        }
    }
    
    #print Dumper @chapternodes;

    # Create array, each element is HTML for 1 chapter
    my @chapters;
    foreach my $child(@chapternodes)
    {
        if ($child->{name} eq 'chapter')
        {
            my @arr = ($child);
            push(@chapters, $self->XMLContentToHTML(\@arr));
        }
    }
    
    # Create directory for all the chapter files
    mkdir($dir);
    
    my $chapnum = 1;
    my @files;
    foreach my $chapter (@chapters)
    {
        my $file = $dir . "/" . $chapnum . ".xhtml";
    my $htmldoc =     <<"EOF";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="$self->{metadata}->{language_iso}">
<head>
    <title>$self->{metadata}->{title} - </title>
    <meta http-equiv="Content-Type" content="application/xhtml+xml; charset=utf-8" />
    <meta name="copyright" content="This text is in the public domain." />
    <meta name="generator" content="SagaDB build mechanism" /> 
    <meta http-equiv="Content-Language" content="$self->{metadata}->{language_iso}" /> 
</head>
<body>

$chapter

</body>
</html>
EOF
        WriteFile($file, $htmldoc);
        push(@files, $file);
        $chapnum++;
    }
    return \@files;
}


sub TranslationNoteFromMetadata
{
    my $metadata = shift @_;

    my $lang = $metadata->{language_iso};
    my $translation;
    
    if (defined($metadata->{trans}))
    {        
        my $tpl = ReadFile("tpl/translated/$lang.translated.tpl");
        foreach my $key (sort(keys(%{$metadata})))
        {
            $tpl =~ s/%%$key%%/$metadata->{$key}/i;
        }
        $translation = $tpl;
    }
    
    return $translation;
}

sub XMLContentToHTML
{
    my $self = shift @_;
    my $arref = shift @_;
    my @children = @{$arref};
    my $html;
    
    my $childcnt = 0;
    
    foreach my $child(@children)
    {
        if ($child->{type} ne 'element'){ next;}
        
        if ($child->{name} eq 'chapter')
        {
            my $number = $child->{attributes}->{number};
            my $title = $child->{attributes}->{title};
            
            #$html .= "\n\n<a name=\"$number\"></a>\n\n";
            
            my $h2 = $lang_chapters{$self->{metadata}->{language_iso}};
            $h2 =~ s/NUM/$number/g;
            if (defined($title) and $title ne '')
            {
                $h2 .= " - " . $title;
            }
            $html .= "<h2 id=\"$number\">$h2</h2>\n";
            
            $html .= $self->XMLContentToHTML($child->{children});
        }
        elsif ($child->{name} eq 'paragraph')
        {
            my $pgtext = $child->{children}->[0]->{content};
            if ($childcnt == 0)
            {
                $html .= "\n<p class=\"firstparagraph\">$pgtext</p>\n";
            }
            else
            {
                $html .= "\n<p>$pgtext</p>\n";
            }
        }
        elsif ($child->{name} eq 'poetry')
        {
            my @pchildren = @{$child->{children}};
            
            $html .= "\n\n<p class=\"poetry\">";
            
            my $childcount = 0;
            foreach my $pchild(@pchildren)
            {
                if ($pchild->{type} ne 'element' || $pchild->{name} ne 'line'){ next;}
                
                my $linetext = $pchild->{children}->[0]->{content};
                $html .= "$linetext";
                if ($childcount ne scalar(@pchildren))
                {
                    $html .= "<br />\n";
                }
                $childcount++;
            }
            
            $html .= "</p>\n\n";
        }
        $childcnt++;
    }
    
    return $html;
}


sub XMLContentToPlainText
{
    my $self = shift @_;
    my $arref = shift @_;
    my @children = @{$arref};
    my $text;
        
    foreach my $child(@children)
    {
        if ($child->{type} ne 'element'){ next;}
        
        if ($child->{name} eq 'chapter')
        {
            my $number = $child->{attributes}->{number};
            my $title = $child->{attributes}->{title};
                        
            my $h2 = $lang_chapters{$self->{metadata}->{language_iso}};
            $h2 =~ s/NUM/$number/g;
            if (defined($title) and $title ne '')
            {
                $h2 .= " - " . $title;
            }
            $text .= "\n\n$h2\n";
            
            $text .= $self->XMLContentToPlainText($child->{children});
        }
        elsif ($child->{name} eq 'paragraph')
        {
            my $pgtext = $child->{children}->[0]->{content};
            
            $text .= "\n$pgtext\n";
        }
        elsif ($child->{name} eq 'poetry')
        {
            my @pchildren = @{$child->{children}};
            
            $text .= "\n\n";
            
            foreach my $pchild(@pchildren)
            {
                if ($pchild->{type} ne 'element' || $pchild->{name} ne 'line'){ next;}
                my $linetext = $pchild->{children}->[0]->{content};
                $text .= "\t$linetext\n";
            }
            
            $text .= "\n";
        }
    }
    
    return $text;
}

1;