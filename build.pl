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

use strict; # yes, oh yes

use File::Basename;
use Data::Dumper;
use Getopt::Std;
use Time::HiRes qw(gettimeofday tv_interval);

# SagaDB modules
use SagaDB::Util;
use SagaDB::XML;
use SagaDB::HTML;

our $VERSION = 2.0;

sub main::HELP_MESSAGE
{
    print STDERR <<"EOF";
SagaDB build script

    Usage: build.pl [-aAhtpemv] [-n basename]
    
        -h Generate plain HTML version
        -t Generate plain text version
        -m Generate HTML pages for website
        -x Generate ZIP archives of all sagas in all formats
        
        -a All of the above options (equivalent to -htmx)
        
        -e Generate EPUB version
        -p Generate PDF version
        -v Generate voice audio files
        
        -A All of the above options (equivalent to -htmxepv)
        
        -n [REQUIRED] Takes saga basename as argument, specify 'all' for all in src dir
        
    e.g. "perl build.pl -A -n all" builds every format for every saga
    
EOF
}

my ($long_date, $iso_timestamp, $standard_date, $time, $year) = GetDate();

# Config
my $srcdir = "src/";
my $textdir = "web/html/files/text/";
my $htmldir = "web/html/files/html/";
my $epubdir = "web/html/files/epub/";
my $pdfdir = "web/html/files/pdf/";
my $zipdir = "web/html/files/zip/";
my $audiodir = "web/html/files/audio/";
my $chapter_htmldir = "web/html/files/chapter_html/";
my $pagesdir = "web/html/";

my $pageframe_tpl = 'tpl/pageframe.tpl';
my $citation_tpl = "tpl/citation.tpl";
my $sagapage_tpl = "tpl/pageframe.tpl";
my $indexaz_tpl = "tpl/index_az.tpl";

# Getopt
$Getopt::Std::STANDARD_HELP_VERSION = 1; # so --help quits after usage string

my $valid_opts = 'aAhtpemvxn:';
my %opts;

getopts($valid_opts, \%opts);

if (!$opts{n}) { main::HELP_MESSAGE() and exit; }

# Use this hash to track which sagas are available in which langauges
my %saga_lang;

# Start timing execution time
my $program_start = [gettimeofday];

# Keep track of no files processed
my $fcount = 0;


# And off we go...

# Read contents of xml source directory
print "Reading source directory\n";
opendir(SRCDIR, $srcdir) or die("Failed to open '$srcdir' directory");
my @datafiles = readdir(SRCDIR);
closedir(SRCDIR);

# Iterate through files, convert
foreach (@datafiles)
{
    # Ignore all hidden or non-xml files
    if ($_ !~ m/\.xml$/ || $_ =~ m/^\./ || -d $_) { next; }    

    # Get basename and saganame
    # basename is SAGANAME.ISOLANG
    my $basename = $_;
    $basename =~ s/\.xml$//g; #Remove xml suffix
    my($fn, $directory, $suffix) = fileparse($basename,  qr/\.[^.]*/);
    $basename = $fn . "$suffix";
    my $saganame = $fn;
    
    if ($opts{n} and $opts{n} !~ m/$basename/ and $opts{n} ne 'all') { next; }
    
    print "Processing '$basename'" . "\n";
    
    # Read in and parse XML file
    my $path = $srcdir . $_;
    print "\tParsing XML source file '$path'\n";
    my $xml_data = ReadFile($path);    
    my $sdbxml = new SagaDB::HTML($xml_data);
    $sdbxml->{metadata} = $sdbxml->ParseMetaData();
    
    # Get meta-data info 
    my $isolang = $sdbxml->{metadata}->{language_iso};
    my $title = $sdbxml->{metadata}->{title};
    my $lang = $sdbxml->{metadata}->{language};
    
    # outfile names
    my $htmlpath = $htmldir . "$basename.html";
    my $txtpath = $textdir . "$basename.txt";
    my $pdfpath = $pdfdir . "$basename.pdf";
    my $epubpath = $epubdir . "$basename.epub";
    my $audiopath = $audiodir . "$basename/";
    
    # Note the language
    if (!defined($saga_lang{$saganame}))
    {
        my @arr = ();
        $saga_lang{$saganame} = \@arr;
    }

    my %info;
    $info{language_iso} = $isolang;
    $info{basename} = $basename;
    $info{language} = $lang;
    $info{title} = $title;
    push(@{$saga_lang{$saganame}}, \%info);
    
    # Convert to plain text
    if ($opts{t} or $opts{a} or $opts{A})
    {
        print "\tCreating Plain Text file '$txtpath'\n";
        $sdbxml->WritePlainTextRepresentationToFile($txtpath);
    }
    
    # Convert to HTML
    if ($opts{h} or $opts{a} or $opts{A})
    {
        print "\tCreating HTML file '$htmlpath'\n";
        $sdbxml->WriteHTMLRepresentationToFile($htmlpath);
    }
    
    # Convert to PDF
    if ($opts{p} or $opts{A})
    {
        print "\tCreating PDF file '$pdfpath'\n";
        my $cmd = "/usr/bin/perl html2pdf.pl '$htmlpath' '$pdfpath'";
        system($cmd);
        #print $cmd . "\n";
    }
    
    # Convert to EPUB
    if ($opts{e} or $opts{A})
    {
        print "\tCreating EPUB file '$epubpath'\n";
        $sdbxml->CreateEPUBAtPath($epubpath);
    }
    
    # Create spoken audio files
    if ($opts{v} or $opts{A})
    {
        print "\tCreating spoken audio files\n";
        if ($isolang ne 'en')
        {
            print "\t\tSkipping, only English supported...\n";
        }
        
        $sdbxml->CreateChapterAudioFilesInDirectory($audiopath);
    }
    
    # This adds audio link to chapter headings
    if (-e $audiopath)
    {
        $sdbxml->{audio} = 1;
    }
    
    # Create website pages
    if ($opts{m} or $opts{a} or $opts{A})
    {
        # Create saga website page
        print "\tCreating HTML website page '$basename.html'\n";
        my $html = $sdbxml->HTMLRepresentationFromTemplate($sagapage_tpl);            
        WriteFile( $pagesdir . $basename . ".html", $html);
        symlink( $basename . ".html", $pagesdir . $basename);
           
        # Create citation page
        my $citationpage = $basename . ".cite.html"; 
        print "\tCreating citation page '$citationpage'\n";
        $html = $sdbxml->HTMLCitationRepresentationFromTemplate($citation_tpl);
        WriteFile( $pagesdir . $basename . ".cite.html", $html);
        
        symlink($basename . ".cite.html", $pagesdir . $basename . ".cite")
    }
    
    print "\n";
    $fcount++;
}

if (!$fcount) { print "0 files processed\n" and exit; }

############## Create download archives ############

if ($opts{x} or $opts{a} or $opts{A})
{
    print "Creating download archives\n";

    # FIXME: These zip cmds assume current directory structure settings

    print "\tRemoving old archives...\n";
    system("rm $zipdir*");

    print "\tCreating HTML archive...\n";
    system("cd $htmldir && zip -r ../zip/all_sagas_html.zip *");

    print "\tCreating Plain Text archive...\n";
    system("cd $textdir && zip -r ../zip/all_sagas_text.zip *");

    print "\tCreating PDF archive...\n";
    system("cd $pdfdir && zip -r ../zip/all_sagas_pdf.zip *");

    print "\tCreating EPUB archive...\n";
    system("cd $epubdir && zip -r ../zip/all_sagas_epub.zip *");

    #print "\tCreating XML source archive\n";
    #system("zip -r $zipdir" . "all_sagas_xml.zip src")

    print "\tCreating SagaDB tools package...\n";
    system("zip -r $zipdir" . "sagadb_tools.zip src tpl xml2txt.pl xml2xhtml.pl html2pdf.pl html2ps build.pl tpl SagaDB*.pm");
    
}

############## Create web index page ##############

if ($opts{m} or $opts{a} or $opts{A}) 
{
    print "\tCreating Saga Index page\n";
    
    ### List by name in 2 columns #####
    my $bynamelist;
    my $numsagas = scalar(keys(%saga_lang));
    my $half = $numsagas/2;
    my $sagacnt = 0;
    my $col1, my $col2;

    foreach my $saganame (sort(keys(%saga_lang)))
    {
      my $saga_fullname_is;
  
      my $li;
      my $is_title;
      foreach my $lang(@{$saga_lang{$saganame}})
      {
          my $isolang = $lang->{language_iso};
          if ($isolang eq 'is') { $is_title = $lang->{title}; }
      
          $li .= "<a href=\"$saganame.$isolang\"><img src=\"/images/flags/$isolang.gif\" class=\"flag\" alt=\"$lang->{title}\"></a>\n";
      }
      $li = "<p style='line-height:12px;'>" . $li . "</p>";
      my $item = "<a href=\"$saganame.is\"><strong>$is_title</strong></a>\n$li\n\n\n";
      
      if ($sagacnt < $half)
      {
          $col1 .= $item;
      }
      else
      {
          $col2 .= $item;
      }
      $sagacnt++;
    }
    $bynamelist = "<ul>\n$bynamelist\n</ul>";
    
    my $bynamelist_html = <<"EOF";
    
    <div class="row">

      <div class="medium-6 columns">
        <div class="callout sbox frontpage-box">
        $col1
        </div>
      </div>
    
    
      <div class="medium-6 columns">
          <div class="callout sbox frontpage-box">
          $col2
          </div>
        </div>
    </div>
    
    <br>
    <br>

EOF
    

    #### List by language ######

    my $bylanglist;
    my %bylang;
    foreach my $saganame (sort(keys(%saga_lang)))
    {
    foreach my $lang(@{$saga_lang{$saganame}})
    {
        my $langname = $lang->{language};
        my $isolang = $lang->{language_iso};
        $bylang{$langname} .= "<li><img src=\"/images/flags/$isolang.gif\"> <a href=\"$saganame.$isolang\">$lang->{title}</a></li>\n";
    }
    }

    foreach my $lang(sort(keys(%bylang)))
    {
      $bylanglist .= "\n<h3>$lang</h3>\n<ul>\n$bylang{$lang}\n</ul>\n";
    }
    
    $bylanglist .= "<br><br>";
    
    
    #### Expand template #########

    my $tpl = ReadFile($indexaz_tpl);

    $tpl =~ s/%%bynamelist%%/$bynamelist_html/;
    $tpl =~ s/%%bylanglist%%/$bylanglist/;

    ##### Create index page ########

    my $frame = ReadFile($pageframe_tpl);
    $frame =~ s/%%content%%/$tpl/gi;
    $frame =~ s/%%title%%/Index of the Icelandic Sagas/gi;
    $frame =~ s/%%language%%/en/gi;
    
    WriteFile( $pagesdir . "index_az.html", $frame);
    print "\tSymlinking to index_az.html from $pagesdir" . "index_az\n\n";
    unlink($pagesdir . "index_az");
    symlink("index_az.html", $pagesdir . "index_az");
    
    
    print "\tCreating other website pages\n";
     
    my @pages = ('downloads', 'about', 'index');
    foreach my $p(@pages)
    {
        my $dest = $pagesdir . "$p.html";
        print "\t\tCreating page $dest\n";
        my $page = ReadFile('tpl/' . $p . ".tpl");
        my $frame = ReadFile($pageframe_tpl);
        $frame =~ s/%%content%%/$page/gi;
        my $display_title = ucfirst($p);
        $frame =~ s/%%title%%/$display_title/gi;
        $frame =~ s/%%language%%/en/gi;
        WriteFile($dest , $frame);
        my $symlink = $pagesdir . $p; 
        my $linksrc = "$p.html";
        print "\t\tSymlinking to $linksrc from $symlink\n";
        unlink($symlink);
        symlink($linksrc, $symlink);
     }
}


my $exec_time = tv_interval($program_start);
print "$fcount source files processed in $exec_time seconds\n";

