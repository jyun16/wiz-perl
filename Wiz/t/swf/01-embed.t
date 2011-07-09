#!/usr/bin/perl

use strict;
use warnings;

use lib qw(
../../lib
../lib
);

use Wiz::Test qw(no_plan);
use Wiz::Constant qw(:common);
use Wiz::SWF::Embed;

chtestdir;

my $INPUT_SWF = "file/input.swf";
my $OUTPUT_SWF = "file/output.swf";
my $OUTPUT_SWF2 = "file/output2.swf";

sub main {
    test_embed();
    test_noembed();
    test_default_output();
    test_change_output();
    cleanup();
    return 0;
}

sub test_embed {
    my $swf = new Wiz::SWF::Embed(file => $INPUT_SWF);
    $swf->embed_vars({ '/:text' => 'fugafuga' });
    is length($swf->data), 190, q|embed_vars - check swf filesize.|;
}

sub test_noembed {
    my $swf = new Wiz::SWF::Embed(file => $INPUT_SWF);
    $swf->embed_vars;
    is length($swf->data), 158, q|embed_vars - noembed check filesize.|;
}

sub test_default_output {
    my $swf = new Wiz::SWF::Embed(
        file        => $INPUT_SWF,
        output_file => $OUTPUT_SWF,
    );
    $swf->embed_vars({ '/:text' => 'fugafuga' });
    is length($swf->data), 190, q|embed_vars - default output.|;
    is -s $OUTPUT_SWF, 190, q|output - default output swf check filesize.|;
}

sub test_change_output {
    my $swf = new Wiz::SWF::Embed(file => $INPUT_SWF);
    $swf->embed_vars({ '/:text' => 'fugafuga' });
    is $swf->output($OUTPUT_SWF2), TRUE, q|embed_vars - change output.|;
    is -s $OUTPUT_SWF2, 190, q|output - change output swf check filesize.|;
}

sub cleanup {
    for ($OUTPUT_SWF, $OUTPUT_SWF2) { `rm -rf $_`; }
}

exit main;
