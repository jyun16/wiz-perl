package Wiz::Test;

use strict;
use warnings;

use Data::Dumper;
use Scalar::Util qw(reftype);
use Digest::MD5;
use Tie::File;
use IO::Scalar;
use IO::Prompt;
use Cwd qw/cwd realpath/;
use File::Basename qw/dirname/;
use Test::Base -Base;

use constant LIST_DELIMITER => ", \n\t\t";

=head1 NAME

Wiz::Test - Wiz Test Framework

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

 # change current working directory
 # to directory which test script is in.
 chtestdir
 
 is_empty "", "empty value";
 not_empty undef, "it's not empty";
 is_defined "", "it's defined value";
 is_undef undef, "it's not defined value";
 has_array [1, 2, 3], [2, 3], "The former has the later";
 eq_hash_keys {a =>1, b =>2}, {a => 2, b => 4}, "hash keys are same";
 has_hash {a => 1, b => 2}, {b => 2}, "The former has the later";
 has_hash_keys {a =>1, b =>2}, {a => 2}, "The former has keys of the later";
 is_die sub {die}, "this code will die";
 like_die_msg sub {die "shinjatta"}, qr/shin/, "die message maching";
 file_equals "/path/to/file1", "/path/to/file2", "their files are equal";
 file_contains "/path/to/file", qr/string/, "file content matching";
 file_contains_at_line "/path/to/file", qr/string/, 0, "1st line of the file match with the regexp";
 file_contents "/path/to/file", "string", "the former file's content is the later string"
 file_contents_at_line "/path/to/file", "string", 0, "1st line of the file is the later string"

=head1 DESCRIPTION

This Test Class is based on Test::Base.
So, you can use all feature of L<Test::Base> and L<Test::More>.
See their document.

In this document, additional test functions are explained.

=head1 EXPORTS

 is_empty
 not_empty
 is_defined
 is_undef
 has_array
 not_has_array
 is_die
 like_die_msg
 file_equals
 file_contains
 file_contains_at_line
 file_contents
 file_contents_at_line
 eq_hash_keys
 has_hash
 has_hash_keys
 not_has_hash_keys
 has_structure
 not_has_structure
 
 chtestdir
 skip_confirm

 _is_test_ng
 _like_test

=cut

our @EXPORT = qw(
    is_empty
    not_empty
    is_defined
    is_undef
    has_array
    not_has_array
    is_die
    like_die_msg
    file_equals
    file_contains
    file_contains_at_line
    file_contents
    file_contents_at_line
    eq_hash_keys
    has_hash
    has_hash_keys
    not_has_hash_keys
    has_structure
    not_has_structure

    run_has_hash

    chtestdir
    skip_confirm

    _is_test_ng
    _like_test
);


=head1 UTILITY FUNCTIONS

=cut

our $_DIAG_IN_LIKE_TEST = 0;
our $SKIP_ENV = 'WIZ_TEST_SKIP_DISABLE';

=head2 chtestdir

This is not test function.
This function change current working directory
to the directory in which test script is.

For example, your test script is C<package/t/test/test.t>.
And the script needs some files which is in C<package/t/test/data/>.
Normally, test is executed in C<package/>, so you have to
write path as like "t/test/data/..." in test script.

If you use this function, you can write path as like "./data/".

And this function modify @INC. For example, test script is "/path/to/t/foo/bar/test.t"
The following paths are pushed to @INC.

 /path/to/t/foo/bar/lib
 /path/to/t/foo/bar
 /path/to/t/foo/lib
 /path/to/t/foo
 /path/to/t/lib
 /path/to/t
 /path/to/lib


=cut

sub chtestdir () {
    my $fullpath = dirname realpath cwd . '/'. $0;
    chdir $fullpath;

    if ($fullpath =~ s{^(.+?)/t/}{/t/}) {
        my $basepath = $1;
        push @INC, $basepath . '/lib';
        while ($fullpath =~s{(/[^/]+)$}{}) {
            push @INC, $basepath . $fullpath . $1 . '/lib', $basepath . $fullpath . $1;
        }
    }

}

=head2 skip_confirm($dialog, $skip_msg, $timeout_sec)

  if (skip_confirm) {
    # do test; 
  }
    
It outputs propmpt  $dialog message or "test run? [y/N]" and waits for user's input.
If user input 'y', it returns 1 and do nothing.
If user input 'n', it returns 0 and use Test::More->builder->skip.
If you pass $timeout_sec, prompt will be skipped after $timeout_sec.

If environmental value 'WIZ_TEST_SKIP_DISABLE'(the name is defined in $Wiz::Test::SKIP_ENV as class variable) is enabled,
this always returns 1.

$dialog, $skip_msg and $timeout_sec are optional.
$dialog is a dialog message, if you omit it or give undef or "" to it, "test run? [y/N]: " is used.
$skip_msg is skip message, which is used when this function return 0.

$timeout_sec is seconds to wait for user input. this can be first or second or third argument.

 skip_confirm($dialog, $skip_msg, $timeout);
 skip_confirm($dialog, $timeout);
 skip_confirm($timeout);

The above is all ok.

B<Note that> this function automatically execute skip function, so you need B<not to execute> test if this function returns 0.

=cut

sub skip_confirm () {
    my ($dialog, $skip_msg, $sec) = @_;
    $sec ||= 0;
    if (@_ == 2 and $skip_msg =~/^\d{1,2}$/) {
        ($skip_msg, $sec)    = ("", $skip_msg);
    } elsif (@_ == 1 and $dialog =~ /^\d{1,2}$/) {
        ($dialog, $sec) = ("", $dialog);
    }
    $dialog ||= $sec ? "test run?(answer in $sec sec) [y/N]: " : "test run? [y/N]: ";
    $ENV{$Wiz::Test::SKIP_ENV} and return 1;
    my $ret;
    local $SIG{'ALRM'};
    local $@;
    eval {
        if (defined $sec and $sec > 0) {
            $SIG{'ALRM'} = sub { die };
            alarm($sec);
        }
        unless($ret = lc prompt($dialog, '-tynd', 'n') eq 'y' ? 1 : 0){
            Test::More->builder->skip($skip_msg);
        }
        if (defined $sec and $sec > 0) {
            alarm(0);
        }
    };
    if ($@) {
        Test::More->builder->skip($skip_msg);
    }
    return $ret;
}


=head1 TEST FUNCTIONS

=cut

sub _ok () {
    my($r, $msg, $got, $expected, $format) = @_;
    $format ||= <<_M_;
          got: %s
     expected: %s
_M_
    my $ret = ok $r, $msg ? $msg : ();
    no warnings "uninitialized";
    diag sprintf $format, $got, $expected unless $ret;
    return $ret;
}

sub _arraydump () {
    my ($array) = @_;
    return "[\n\t\t@$array\n\t]";
}

sub _like_test () {
    my($code, $regex, $msg) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 2;
    croak "not code: " . ($code || '')  unless ref $code;
    my $data = "";
    my $sh = IO::Scalar->new(\$data);
    my $builder = Test::More->builder;
    my $stdout = $builder->output;
    my $stderr = $builder->failure_output;
    $builder->output($sh);
    $builder->failure_output($sh);
    eval {
        $code->();
    };
    if ($_DIAG_IN_LIKE_TEST) {
        print $data;
    }
    _to_regexp(\$regex);
    $builder->output($stdout);
    $builder->failure_output($stderr);
    my $r;
    {
        local $TODO = qq{: It's not TODO, but NG test};
        $r = _ok( ($data =~ $regex) ? 1: 0, $msg, $regex, $data);
    }
    return $r;
}

sub _is_test_ng () {
    my ($code, $msg) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    {
        local $TODO = qq{: It's not TODO, but NG test};
        _like_test($code, qr/^not ok/, $msg);
    }
}

=head2 is_empty $str, $name

If $str is empty, the test is ok.
empty means "". So if you pass undef as $str, the test fails.

=cut

sub is_empty () {
    my ($t, $msg) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 2;
    my $r = (defined $t and $t eq '');
    _ok $r, $msg, (defined $t ? "'$t'" : "undefined value"), 'empty value';
}

=head2 not_empty $str, $name

If $str isn't empty, the test is ok.
empty means "". So if you pass undef as $str, the test passes.

=cut

sub not_empty () {
    my ($t, $msg) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 2;
    my $r = not(defined $t and $t eq '');
    _ok $r, $msg, defined $t ? "'$t'" : 'undefined value', 'not empty value';
}

=head2 is_defined $str, $name

If $str is defined, the test is ok.

=cut

sub is_defined () {
    my ($t, $msg) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 2;
    my $r = defined $t;
    _ok $r, $msg, $r ? "'$t'" : "undefined value", 'defined value';
}

=head2 is_undef $str, $name

If $str isn't defined, the test is ok.

=cut

sub is_undef () {
    my ($t, $msg) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 2;
    my $r = not(defined $t);
    _ok $r, $msg, defined $t ? "'$t'" : "undefined value", 'not defined value';
}

=head2 has_array $arrayref, $arrayref2, $name

If the former arrayref has the later arrayref, the test is ok.
Note that: this test is not deep check.

=cut

*has_array = \&has_structure;

=head2 not_has_array $arrayref, $arrayref2, $name

If the former arrayref dosen't has the later arrayref, the test is ok.
Note that: this test is not deep check.

=cut

sub not_has_array () {
    my ($t1, $t2, $msg) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 2;
    my %tmp;
    @tmp{@$t1} = ();
    my $cnt = 0;
    my @has;
    foreach my $e (@$t2) {
        exists $tmp{$e} and push @has, $e;
    }
    my $r = @has == 0;
    local $" = LIST_DELIMITER;
    _ok($r, $msg, "\n\t" . _arraydump($t1), "\n\t" . _arraydump(\@has) . ' of ' . _arraydump($t2), <<_M_);
          got: %s
         have: %s
_M_
}

=head2 eq_hash_keys $hashref, $hashref2, $name

If keys of the two hashref is same, the test is ok.
Note that: this test is not deep check.

=cut

sub eq_hash_keys () {
    my ($h1, $h2, $msg) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 2;
    my $r = eq_set([keys %$h1], [keys %$h2]);
    my @not_in = ([], []);
    if(not $r) {
        my @hash = ($h1, $h2);
        foreach my $index (0, -1) {
            foreach my $k (keys %{$hash[$index]}) {
                push @{$not_in[$index]},$k if not exists $hash[$index + 1]->{$k}
            }
        }
    }
    local $" = LIST_DELIMITER;
    _ok($r, $msg, "\n\t" . _arraydump($not_in[1]), "\n\t" . _arraydump$not_in[0], <<_M_);
      got has: %s
 expected has: %s
_M_
}

=head2 has_hash $hashref, $hashref2, $name

If the former hashref has the later hashref, the test is ok.

=cut

*has_hash = \&has_structure;

sub has_structure () {
    my ($t1, $t2, $msg) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 2;
    local $Data::Dumper::Terse = 1;          # don't output names where feasible
    my $missing = _has_structure(reftype $t2, $t1, $t2);
    _ok(defined $missing ? 0 : 1, $msg, Dumper($t1), Dumper($missing), <<_M_);
          got: %s
      missing: %s
_M_
}

sub _has_structure () {
    my ($r, $t1, $t2, $b) = @_;

    $r ||= '';
    if ($r eq 'HASH') { return _has_hash($t1, $t2, $b); }
    elsif ($r eq 'ARRAY') { return _has_array($t1, $t2, $b); }
    elsif ($r eq 'SCALAR') { return _has_scalar($$t1, $$t2, $b); }
    else { return _has_scalar($t1, $t2, $b); }
}

sub _has_hash () {
    my ($t1, $t2, $b) = @_;

    no warnings 'uninitialized';
    reftype $t1 ne 'HASH' and return $t1;
    my %miss = ();
    for (keys %$t2) {
        my $m = _has_structure(reftype $t2->{$_}, $t1->{$_}, $t2->{$_}, $b);
        defined $m and $miss{$_} = ref $m eq 'SCALAR' ? $$m : $m;
    }
    return %miss ? \%miss : undef;
}

sub _has_array () {
    my ($t1, $t2, $b) = @_;

    my @miss = ();
    for my $a2 (@$t2) {
        my $r = reftype $a2;
        my @m = ();
        my $m = undef;
        for my $a1 (@$t1) {
            $m = _has_structure($r, $a1, $a2, $b);
            if (defined $m) { push @m, ref $m eq 'SCALAR' ? $$m : $m; }
            else { @m = (); last; }
        }
        @m and push @miss, $a2;
    }
    return @miss ? \@miss : undef;
}

sub _has_scalar () {
    my ($s1, $s2, $b) = @_;

    return (defined $b and $b == 0) ? 
        (defined $s1 and $s1 eq $s2) ? \$s2 : undef :
        (not defined $s1 or $s1 ne $s2) ? \$s2 : undef;
}

sub not_has_structure () {
    my ($t1, $t2, $msg) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 2;
    local $Data::Dumper::Terse = 1;          # don't output names where feasible
    my $missing = _has_structure(reftype $t2, $t1, $t2, 0);
    _ok(defined $missing ? 0 : 1, $msg, Dumper($t1), Dumper($missing), <<_M_);
          got: %s
      missing: %s
_M_
}

=head2 has_hash_keys $hashref, $hashref2, $name

If the keys of the the later hashref is included in
the keys of the former hashref, the test is ok.

=cut

sub has_hash_keys () {
    my ($t1, $t2, $msg) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 2;
    local $Data::Dumper::Terse = 1;          # don't output names where feasible

    my $missing = _has_hash_keys($t1, $t2);
    _ok(defined $missing ? 0 : 1, $msg, Dumper($t1), Dumper($missing), <<_M_);
     got keys: %s
expected keys: %s
_M_
}

sub not_has_hash_keys () {
    my ($t1, $t2, $msg) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 2;
    local $Data::Dumper::Terse = 1;          # don't output names where feasible

    my $missing = _has_hash_keys($t1, $t2, 0);
    _ok(defined $missing ? 0 : 1, $msg, Dumper($t1), Dumper($missing), <<_M_);
     got keys: %s
expected keys: %s
_M_
}

sub _has_hash_keys () {
    my ($t1, $t2, $b) = @_;

    my %miss = ();
    for (keys %$t2) {
        if (defined $b and $b == 0) {
            if (ref $t1->{$_} eq '') { exists $t1->{$_} and $miss{$_} = 1; }
            else {
                my $m = _has_hash_keys($t1->{$_}, $t2->{$_}, $b);
                defined $m and $miss{$_} = $m;
            }
        }
        else {
            if (not exists $t1->{$_}) { $miss{$_} = 1; }
            elsif (ref $t1->{$_} eq 'HASH') {
                my $m = _has_hash_keys($t1->{$_}, $t2->{$_}, $b);
                defined $m and $miss{$_} = $m;
            }
        }
    }
    return %miss ? \%miss : undef;
}

=head2 is_die $code, $name

If $code will die, the test is ok.

=cut

sub is_die () {
    my ($code, $msg) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 2;
    eval {
        $code->();
    };
    my $r = $@ ? 1 : 0;
    _ok $r, $msg, "code is success", "", <<_M_;
     expected: %s
_M_
}

=head2 like_die_msg $code, $regexp, $name

If $code will die and the message match with $regexp,
the test is ok.

=cut

sub like_die_msg () {
    my ($code, $regex, $msg) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    eval {
        $code->();
    };
    _to_regexp(\$regex);
    ok $@ =~ $regex ? 1 : 0, $msg;
}

=head2 file_equals $path_to_file1, $path_to_file2, $name

The former file and the later file are same, the test is ok.
This check MD5 checksum of both files.
If files are not same, their differens is outputed with Text::Diff.

=cut

sub file_equals () {
    my ($f1, $f2, $msg) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 2;
    my @md5;
    foreach my $file ($f1, $f2) {
        my $md5 = Digest::MD5->new();
        open my $fh, $file or croak "$! : cannot open $file";
        $md5->addfile($fh);
        close $fh;
        push @md5, $md5->hexdigest();
    }

    my $diff = '';
    my $r = $md5[0] eq $md5[1];
    if (not $r and Test::Base::have_text_diff) {
        my $e = _slurp($f1);
        my $a = _slurp($f2);
        $diff = Text::Diff::diff(\$e, \$a);
    }
    _ok $r, $msg, $f2, $f1, <<_M_;
     Files are different.
     Diff between '%s' and '%s':
 $diff
_M_
}

=head2 file_contains $path_to_file, $regexp, $name

File contents match with $regexp, the test is ok.

=cut

sub file_contains () {
    my ($path, $regex, $msg) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 2;
    my $contents = _slurp($path);
    _to_regexp(\$regex);
    _ok $contents =~ $regex ? 1 : 0, $msg, $contents, $regex, <<_M_;
          got: %s
    not match: %s
_M_
}

=head2 file_contains_at_line $path_to_file, $line, $regexp, $name

$line-th file contents match with $regexp, the test is ok.
line number is 0 origin. 1st line is 0.

=cut

sub file_contains_at_line () {
    my ($path, $line, $regex, $msg) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 2;
    tie my @file, 'Tie::File', $path or croak "$! : cannot open $path";
    _to_regexp(\$regex);
    _ok $file[$line] =~ $regex ? 1 : 0, $msg, $file[$line], $regex, <<_M_;
          got: %s
    not match: %s
_M_
}

=head2 file_contents $path_to_file, $str, $name

File contents is as same as $str, the test is ok.

=cut

sub file_contents () {
    my($path, $expected, $msg) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $contents = _slurp($path);
    is $contents, $expected, $msg;
}

=head2 file_contents_at_line $path_to_file, $line, $str, $name

$line-th file content is as same as $str, the test is ok.
line number is 0 origin. 1st line is 0.

=cut

sub file_contents_at_line () {
    my($path, $line, $expected, $msg) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    tie my @file, 'Tie::File', $path or croak "$! : cannot open $path;";
    is $file[$line], $expected, $msg;
}

sub _slurp () {
    my $path = shift;
    local $/ = undef;
    open my $fh, $path or croak "$! : cannot open $path";
    my $contents = <$fh>;
    close $fh;
    return $contents;
}

sub _to_regexp () {
    my $regexp = shift;
    $$regexp = qr/$$regexp/ if ref $$regexp ne 'Regexp';
    return $regexp;
}


=head1 TEST RUN FUNCTIONS

=head2 run_has_hash input => 'expected'

It is like run_is, run_compare etc. in Test::Base.
This command use hash_hash to compare.

=cut


sub run_has_hash() {
    (my ($self), @_) = find_my_self(@_);
    $self->_assert_plan;
    my ($x, $y) = $self->_section_names(@_);
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    for my $block (@{$self->block_list}) {
        next unless exists($block->{$x}) and exists($block->{$y});
        $block->run_filters unless $block->is_filtered;
        if (ref $block->$x) {
            has_hash($block->$x, $block->$y,
                $block->name ? $block->name : ());
        }
    }
}


=head1 HOW TO EXTENT THIS TEST CLASS?

This is simple tutorial when you want to add some functions in this class and
how to write the tests of the new test functions.

But, actual example is this Test class and test code of this class,
so check the source code and test script,  after reading this tutorial.

=head2 How to write new test functions?

Basically, you must memorize two rule.

 sub test_function () {
     local $Test::Builder::Level = $Test::Builder::Level + 1;
     # ...
 }

The parentheses next to function name is needed for your new test function
or you can write "C<(my ($self), @_) = find_my_self(@_);>" as first line of the subroutine.
And C<local $Test::Builder::Level = $Test::Builder::Level + 1;> is needed, but it is case by case.

The former is ingy's black magic, you don't need to know why it's needed(and I don't know why).
About the later, if you want to use test functions in Test::Base, Test::More,
you need to write this. It tells that the actual test is not here, but in 1 level upper.
If you don't write it and test fails, test claims the line of this test class.

If you call another function in this C<test_function> and, in the function, actual test is done,
You need to write like the following.

  local $Test::Builder::Level = $Test::Builder::Level + 2;

=head2 Need I learn TAP?

TAP(Test Anything Protocol) is very simple protocol,
maybe you can master it soon. But you don't need to learn it.
You can just use functions of Test::More for your test.

If you need a bit complicate test outputs,
this class has one functions C<_ok>. Use it as the following.

 _ok $result, $name, $got, $expected, $format;

For example, C<is_defined> test function is:

 sub is_defined () {
     my ($t, $msg) = @_;
     local $Test::Builder::Level = $Test::Builder::Level + 2;
     my $r = defined $t;
     _ok $r, $msg, $r ? "'$t'" : "undefined value", 'defined value';
 }

C<$r> is test result.
C<$r ? "'$t'" : "undefined value"> is the value passed to this test.
C<'defined value'> is the expected value of this test.

Then you write the test:

 is_defined "", "defined value";
 is_defined undef, "defined value";

The test outputs the following:

 ok 1 - defined value
 not ok 2 - defined value
 #   Failed test 'defined value'
 #   in t/test/simple.t at line 5.
 #           got: undefined value
 #      expected: defined value
 1..2
 # Looks like you failed 1 test of 2.

If you want another type of dialog message, you can change it
to pass the format as the last argument of C<_ok>.

 sub is_defined () {
     my ($t, $msg) = @_;
     local $Test::Builder::Level = $Test::Builder::Level + 2;
     my $r = defined $t;
     _ok $r, $msg, $r ? "'$t'" : "undefined value", 'defined value', <<_EOL_;
      test got: %s
 test expected: %s
 _EOL_
 }

The test outputs the following:

 not ok 2 - defined value
 #   Failed test 'defined value'
 #   in t/test/simple.t at line 5.
 #       test got: undefined value
 #  test expected: defined value
 1..2
 # Looks like you failed 1 test of 2.

=head2 How to test the new test function?

Just use the new test function for OK test.
For NG test, this class prepare 2 functions.

 _is_test_ng $test_code, $name;

$test_code outputs "not ok", the test is ok.

 _like_test $test_code, $regexp, $name;

The output of $test_code match with $regexp, the test is ok.
This can be used not only for ng test, but also for ok test.

If you want to check the output of ng test. Set true value to
C<$Wiz::Test::_DIAG_IN_LIKE_TEST>. Then you can see the diag messages.

=head1 AUTHOR

Kato Atsushi C<< <kato@adways.net> >>
[Base idea] Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 The Wiz Project. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE WIZ PROJECT ``AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED.  IN NO EVENT SHALL THE WIZ PROJECT OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OROTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are
those of the authors and should not be interpreted as representing official
policies, either expressed or implied, of the Wiz Project.

Additionally, the followings are recommended for the developers
to modify/improve/extend Wiz. Please send modified code/patch to mail list,
wiz-perl@googlegroups.com.
The source you sent will be merged into Wiz package.
We welcome anyone who cooperates with us in developing this software.

We'll invite you to this project's member.

=cut

1;

__END__
