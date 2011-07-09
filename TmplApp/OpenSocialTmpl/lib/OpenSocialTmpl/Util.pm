package OpenSocialTmpl::Util;

use strict;

use Wiz::ConstantExporter [qw(
    load_file4js
)];

sub load_file4js {
    my ($path) = @_;
    my $ret;
    open my $f, '<', $path or die "Can't open $path ($!)";
    while (<$f>) {
        s/\r?\n$//;
        s/"/\\"/;
        $ret .= "$_\\\n";
    }
    $ret =~ s/\\\n?$//;
    close $path;
    return $ret;
}

1;
