# sagadb.org

These are the source files and build scripts used to maintain the [Icelandic Saga Database](https://sagadb.org).

The data files are stored as XML in the `src` directory, and can be converted into a variety of different formats, including:

* HTML web pages for the sagadb.org website
* XHTML
* PDF (using html2ps and ps2pdf)
* Plain text (UTF-8)
* EPUB
* Synthesized speech audio files (English only, using the macOS Speech Synthesizer)

The scripts and modules for working with the source XML files are written in Perl and use XML::Parser::Lite::Tree and EBook::EPUB modules.

All saga source texts are in the public domain.

All code is BSD licensed.
