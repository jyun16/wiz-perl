#!/usr/bin/perl

use strict;

use Cwd;
use Archive::Extract;

our $VERSION = '1.0';

my %conf = (
    to  => './modules',
);

my $args = init_args(<<'EOS');
v(version)
h(help)
-notest
-yesall
EOS

$| = 1;

sub main {
    my $seq = get_install_sequence();
    extract_all($seq);
    install_all($seq);
    return 0;
}

sub extract_all {
    my ($seq) = @_;
    confirm("Extract tar ball in $args->{to}?", 'y') or return;
    for (@$seq) {
        print "extract: $_->{file}\n";
        my $ae = new Archive::Extract(archive => "$args->{to}/$_->{file}");
        $ae->extract(to => $args->{to});
    }
}

sub install_all {
    my ($seq) = @_;
    confirm("Install perl modules in $args->{to}?", 'y') or return;
    confirm("Skip make test?") and $args->{notest} = 1;
    confirm("Force install?") and $args->{yesall} = 1;
    for (@$seq) {
        perlv_check($_->{options}) or next;
        print "====[ Install $_->{package}($_->{file}) ]====\n";
        module_install($_);
    }
}

sub perlv_check {
    my ($options) = @_;

    my $perlv = $options->{perlv};
    $perlv or return 1;
    if ($perlv->{'>'}) { $] > $perlv->{'>'} or return 0; }
    elsif ($perlv->{'<'}) { $] < $perlv->{'<'} or return 0; }
    elsif ($perlv->{'='}) { $] = $perlv->{'='} or return 0; }
    return 1;
}

sub module_install {
    my ($info) = @_;

    my $file = $info->{file};
    $file =~ s/\.tar\.gz$//;
    unless (-d "$args->{to}/$file") { print "skip\n"; return; }

    my $package = $info->{package};
    my $cur_version = get_package_version($package);
    unless (defined $cur_version) {
        (my $file_package = $file) =~ s/-/::/g;
        $file_package =~ s/::[\.\d]*$//;
        $cur_version = get_package_version($file_package);
    }

    my $version = $info->{version};
    if (defined $cur_version) {
        if ($cur_version == $version) {
            print "Already installed\n";
            return;
        }
        else {
            confirm("Already installed $package($cur_version). Do you install $version?")
                or return;
        }
    }

    my $cwd = Cwd::cwd;
    chdir "$args->{to}/$file" or die "can't chdir to $args->{to}/$file ($!)";
    system 'perl Makefile.PL';
    system 'make';
    if ($info->{options}{notest} eq '' and $args->{notest} eq '') { print `make test`; }
    system 'make install';
    chdir $cwd;
}

sub get_install_sequence {
    my @ret = ();
    open FILE, "<$args->{to}/.modules" or die "can't open file $args->{to}/.modules ($!)";
    while (<FILE>) {
        chomp;
        defined $_ or next;
        my ($p, $v, $f, $o) = split /,/;
        my %opts = ();
        for (split /\|/, $o) {
            my ($key, $ope, $val) = /([^=<>]*)([=<>])?(.*)/;
            if ($key eq 'perlv') { $opts{$key}{$ope} = $val; }
            else { $opts{$key} = $val ne '' ? $val : 1; }
        }

        push @ret, {
            package => $p,
            version => $v,
            file    => $f,
            options => \%opts,
        };
    }
    close FILE;
    return \@ret;
}

sub confirm {
    my ($msg, $default) = @_;
    my $ret = lc prompt("$msg [" . ($default eq 'y' ? "Y/n" : "y/N") . "]: ");
    defined $default and $ret ||= $default;
    return $ret =~ /^y/;
}

sub prompt {
    my ($msg) = @_;
    $args->{yesall} and return 'y';
    print "$msg";
    while(<STDIN>) {
        s/\r?\n$//; 
        return $_;
    }
}

sub init_args {
    my $args_pattern = shift;

    my $args = getopts($args_pattern);

    if (defined $args->{h}) { usage(); exit 0; }
    elsif (defined $args->{v}) { version(); exit 0; }

    $args->{to} ||= $conf{to};

    return $args;
}

sub version {
    print <<EOS;
VERSION: $VERSION

          powered by Junichiro NAKAMURA
EOS
}

sub usage {
    print <<EOS;
USAGE: cpan_install_depend_modules.pl [ OPTIONS ]

OPTIONS:

    --notest: don't test
    --yesall: auto input to prompt yes

EOS
}

sub get_package_version {
    my ($package) = @_;
    local ($@, $!);
    eval "require $package";
    if ($@) { return undef; }
    else { $package->VERSION; }
}

sub getopts {
    my $args_pattern = shift;

    my $p = getopts_pattern($args_pattern);
    my %ret = ();
    my $args_cnt = 0;
    my @no_opt_args = ();
    for (my $i = 0; $i < @ARGV; $i++) {
        my ($a, $o, $v) = ($ARGV[$i], undef, undef);
        if ($a =~ /^-/) {
            $a =~ /^([^=]*)=?(.*)/;
            $o = $1; $v = $2;
            exists $p->{$o} or print "no such option -> $o\n" and exit 1;
            $a = $o;
            $o =~ s/^-*//g;
        }
        else {
            $ret{$args_cnt} = $a;
            push @no_opt_args, $a;
            ++$args_cnt;
        }

        if ($p->{$a} eq 's' or $p->{$a} eq 'l') {
            $ret{$o} = 1;
            set_opt_map(\%ret, $p, $o, 1);
        }
        elsif ($p->{$a} eq 'sv' or $p->{$a} eq 'lv') {
            $v eq '' and $v = $ARGV[++$i];
            if ($v eq '') {
                print STDERR "$a option must be given any value.\n";
                exit 1;
            }

            $ret{$o} = $v;
            set_opt_map(\%ret,$p, $o, $v);
        }
        elsif ($p->{$a} eq 'sa' or $p->{$a} eq 'la') {
            if ($ARGV[$i + 1] !~ /^-/) {
                $v eq '' and $v = $ARGV[++$i];
                $ret{$o} = $v;
                set_opt_map(\%ret, $p, $o, $v);
            }
            else {
                set_opt_map(\%ret, $p, $o, 1);
            }
        }
        elsif ($p->{$a} eq 'sm' or $p->{$a} eq 'lm') {
            ++$i;
            for (my $j = $i; $j < @ARGV; $j++) {
                if ($ARGV[$j] !~ /^-/) {
                    my $v = $ARGV[$j];
                    push @{$ret{$o}}, $v;
                    set_opt_map(\%ret, $p, $o, $ret{$o});
                    ++$i;
                }
                else {
                    --$i; last;
                }
            }
        }
    }
    
    @no_opt_args and $ret{no_opt_args} = \@no_opt_args;
    return wantarray ? (\%ret, $p->{'--slmap'}, $p->{'---lsmap'}) : \%ret;
}

sub getopts_pattern {
    my $args_pattern = shift;

    $args_pattern =~ s/\r?\n//g;

    my %ret = ();
    for my $c ($args_pattern =~ m/(?:-[^-:;@]*[:;@]?)|(?:.\(.*?\)[:;@]?)|(?:.[:;@]?)/g) {
        if ($c =~ /\(/) {
            $c =~ /(.)\((.*?)\)([:;@]?)/;

            if ($3 eq ':') { $ret{-$1} = 'sv'; $ret{'--' . $2} = 'lv'; }
            elsif ($3 eq ';') { $ret{-$1} = 'sa'; $ret{'--' . $2} = 'la'; }
            elsif ($3 eq '@') { $ret{-$1} = 'sm'; $ret{'--' . $2} = 'lm'; }
            else { $ret{-$1} = 's'; $ret{'--' . $2} = 'l'; }

            $ret{'---slmap'}{$1} = $2;
            $ret{'---lsmap'}{$2} = $1;
        }
        else {
            $c =~ /(-?[^-:;@]*)([:;@]?)/;
            my $o = $1;
            my $f = $2;
            if ($c =~ /^-/) {
                if ($f eq ':') { $ret{'-' . $o} = 'lv'; }
                elsif ($f eq ';') { $ret{'-' . $o} = 'la'; }
                elsif ($f eq '@') { $ret{'-' . $o} = 'lm'; }
                else { $ret{'-' . $o} = 'l'; }
            }
            else {
                $ret{-$o} = $f ? 'sv' : 's';
            }
        }
    }

    return \%ret;
}

sub set_opt_map {
    my ($map, $pattern, $key, $value) = @_;

    for (qw(---slmap ---lsmap)) {
        exists $pattern->{$_}{$key} and 
            $map->{$pattern->{$_}{$key}} = $value;
    }
}

exit main;

__END__
