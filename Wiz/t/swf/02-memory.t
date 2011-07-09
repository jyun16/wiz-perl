#!/usr/bin/perl

use strict;
use warnings;

use lib qw(
../../lib
../lib
);

use SWF::Parser;
use SWF::Element;
use Wiz::Test qw(no_plan);
use Wiz::Constant qw(:common);
use Wiz::SWF::Memory;

chtestdir;

my $EMBED_JPG = 'file/red_circle.jpg';
my $INPUT_SWF = 'file/input_memory.swf';
my $OUTPUT_SWF = 'file/output_memory.swf';

sub main {
    test_embed_parse();
    cleanup();
    return 0;
}

sub test_embed_parse {
    my ($output, $swf_data);
    my $parser = SWF::Parser->new(
        'header-callback' => sub {
            my $self = shift;
            my ($signature, $version, $length, $xmin, $ymin, $xmax, $ymax, $framerate, $framecount) = @_; 
            $output = Wiz::SWF::Memory->new(
                \$swf_data, 
                undef, 
                Version   => $version,
                FrameRate => $framerate,
                FrameSize => [$xmin, $ymin, $xmax, $ymax]
            );
        },  
        'tag-callback' => sub {
            my $self = shift;
            my ($tagno, $length, $stream) = @_; 
            my $tag = SWF::Element::Tag->new(Tag => $tagno, Length => $length);
            $tag->unpack($stream);
            if (ref $tag eq "SWF::Element::Tag::DefineBitsJPEG2" 
                && ref $tag->[2] eq "SWF::Element::BinData") {
                open my $fh, '<', $EMBED_JPG or die $!;
                binmode $fh;
                #diff 3640646143 => D8FFD9FF => FFD8 FFD9
                $tag->[2] = new SWF::Element::BinData->add(pack('H8', 'FFD8FFD9'). join '', <$fh>);
                close $fh;
            }
            $tag->pack($output);
        }   
    );  
    $parser->parse_file($INPUT_SWF);
    $output->save;

    is length($swf_data), 2082, q|change image of jpeg.|;
}

sub cleanup {
    for ($OUTPUT_SWF) { `rm -rf $_`; }
}

exit main;
