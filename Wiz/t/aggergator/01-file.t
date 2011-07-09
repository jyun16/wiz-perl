#!/usr/bin/perl

use strict;
use warnings;

use lib qw(
../../lib
../lib
);

{
    package Test::Aggregator::Summary;

    use Wiz::Noose;

    extends 'Wiz::Aggregator::File';

    sub job {
        my $self = shift;
        my ($in, $out, $id) = @_;

        my $sum = 0;
        while (my $line = $in->getline) { $sum += $line; }
        $out->print($sum);
    }

    sub summarize {
        my $self = shift;
        my ($ins) = @_;

        my $sum = 0;
        for (@$ins) { while (my $line = $_->getline) { $sum += $line; } }
        return $sum;
    }

    1;
}

{
    package Test::Aggregator::FailedFork;

    use Wiz::Noose;

    extends 'Wiz::Aggregator::File';
    
    sub job {
        my $self = shift;
        my ($in, $out, $id) = @_;

        $id == 1 and exit 1;
        while (my $line = $in->getline) { $out->print($line); }
    }
    sub summarize { }

    1;
}

{
    package Test::Aggregator::RetryFork;

    use Wiz::Noose;

    extends 'Wiz::Aggregator::File';
    
    sub job {
        my $self = shift;
        my ($in, $out, $id) = @_;

        $self->try_count != 1 && $id == 1 and exit 1;
        my $sum = 0;
        while (my $line = $in->getline) { $sum += $line; }
        $out->print($sum);
    }

    sub summarize { 
        my $self = shift;
        my ($ins) = @_;
        my $sum = 0;
        for (@$ins) { while (my $line = $_->getline) { $sum += $line; } }
        return $sum;
    }

    1;
}

package main;

use Wiz::Test qw(no_plan);
use Wiz::Constant qw(:common);
use Wiz::Util::File qw(file_read2str ls);

chtestdir;

my $TMP_DIR = 'log/';
my $TEST_FILE = 'log/test_data';
my $TEST_FILE2 = 'log/test_data2';
my $OUTPUT_FILE = 'log/output';
my $FORK_PROCESS = 3;

sub main {
    test_run();
    test_fork_run();
    test_retry_fork_run();
    test_retry_error_fork_run();
    test_multi_file_run();
    return 0;
}

sub test_run {
    my $aggregator = new Test::Aggregator::Summary(
        output        => $OUTPUT_FILE,
        path          => $TEST_FILE,
        process       => 1,
        tmp_dir       => $TMP_DIR,
    );
    $aggregator->run;
    is -f $OUTPUT_FILE, TRUE, q|single process - output data|;
    is file_read2str($OUTPUT_FILE), 465, q|single process - summrize|;
    
    my $input_file = $TMP_DIR. $aggregator->_key($aggregator->sep_prefix, 1);
    my $output_file = $TMP_DIR. $aggregator->_key($aggregator->result_prefix, 1);
    my $bool = -f $input_file && -f $output_file;
    $aggregator->cleanup;
    $bool and $bool = ! -f $input_file && ! -f $output_file;
    is $bool, TRUE, q|single process - cleanup|;
}

sub test_fork_run {
    my $aggregator = new Test::Aggregator::Summary(
        output        => $OUTPUT_FILE,
        path          => $TEST_FILE2,
        process       => $FORK_PROCESS,
        tmp_dir       => $TMP_DIR,
    );
    $aggregator->run;
    is -f $OUTPUT_FILE, TRUE, qq|fork $FORK_PROCESS process - output data|;
    is file_read2str($OUTPUT_FILE), 412, qq|fork $FORK_PROCESS process - summrize|;
    
    my $bool = TRUE;
    for (1..$aggregator->process) {
        my $input_file = $TMP_DIR. $aggregator->_key($aggregator->sep_prefix, $_);
        my $output_file = $TMP_DIR. $aggregator->_key($aggregator->result_prefix, $_);
        $bool = -f $input_file && -f $output_file;
    }
    $aggregator->cleanup;
    for (1..$aggregator->process) {
        my $input_file = $TMP_DIR. $aggregator->_key($aggregator->sep_prefix, $_);
        my $output_file = $TMP_DIR. $aggregator->_key($aggregator->result_prefix, $_);
        $bool and $bool = ! -f $input_file && ! -f $output_file;
    }
    is $bool, TRUE, qq|fork $FORK_PROCESS process - cleanup|;
}

sub test_retry_fork_run {
    my $aggregator = new Test::Aggregator::RetryFork(
        output        => $OUTPUT_FILE,
        path          => $TEST_FILE2,
        process       => $FORK_PROCESS,
        tmp_dir       => $TMP_DIR,
        force_cleanup => TRUE,
    );
    $aggregator->run;
    is -f $OUTPUT_FILE, TRUE, qq|fork $FORK_PROCESS process - retry output data|;
    is file_read2str($OUTPUT_FILE), 412, qq|fork $FORK_PROCESS process - retry summrize|;

    my $bool = TRUE;
    for (1..$aggregator->process) {
        my $input_file = $TMP_DIR. $aggregator->_key($aggregator->sep_prefix, $_);
        my $output_file = $TMP_DIR. $aggregator->_key($aggregator->result_prefix, $_);
        $bool and $bool = ! -f $input_file && ! -f $output_file;
    }
    is $bool, TRUE, qq|fork $FORK_PROCESS process - force cleanup|;
}

sub test_retry_error_fork_run {
    my $aggregator = new Test::Aggregator::FailedFork(
        output        => $OUTPUT_FILE,
        path          => $TEST_FILE,
        process       => $FORK_PROCESS,
        tmp_dir       => $TMP_DIR,
        force_cleanup => 1,
    );
    $aggregator->run;
    is $aggregator->error2str, 
        '_multi_run : over than try_count!! error id :1', 
        qq|fork $FORK_PROCESS process - failed fork test|;
}

sub test_multi_file_run {
    my $aggregator = new Test::Aggregator::Summary(
        output        => $OUTPUT_FILE,
        path          => [
            $TEST_FILE,
            $TEST_FILE2,
        ],
        process       => 1,
        tmp_dir       => $TMP_DIR,
        force_cleanup => TRUE,
    );
    $aggregator->run;
    is file_read2str($OUTPUT_FILE), 877, q|multi file test|;
}

exit main;

