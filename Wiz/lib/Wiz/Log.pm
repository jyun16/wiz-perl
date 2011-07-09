package Wiz::Log;

use strict;
use warnings;

=head1 NAME

Wiz::Log - Logger

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

 use Wiz::Log;
 
 my $log = new Wiz::Log(

    ### output a message to stdout when message level is 'WARN' or above.
    stdout       => {
        level        => WARN,
    },
        
    ### output a message to stderr when message level is 'ERROR' or above.
    stderr       => {
        level        => ERROR,
    },

    ### output a message to file 'log.dat' when message level is 'WARN' or above.
    file         => {
        path         => 'log.dat', 
        level        => WARN,
        open         => TRUE,
        autoflush    => TRUE,            
    },
        
    ### send a mail using a configuration in 'logmail.conf'
    ### to admin@adways.net when a message level is 'FATAL'
    mail         => {
        _conf        => 'logmail.conf',
        config       => { To => 'admin@adways.net' },
        level        => FATAL, 
    },
        
    ### output a message to syslog when message level is 'INFO' or above.
    syslog       => { 
        ident        => 'work1',
        facility     => 'local0',
        level        => INFO,
        open         => TRUE,
    },   
 );
    
 $log->fatal('Fatal Error');

 $log->write(DEBUG, 'DEBUG LOG')
 $log->write('debug', 'DEBUG LOG')

=head1 DESCRIPTION

Output a message to log.
One or more destinations must be specified, which are the followings.

 stdout stderr file mail syslog
    
=head1 EXPORTS

 FATAL       => 0
 ERROR       => 1
 WARN        => 2
 INFO        => 3
 LOGGING     => 4
 DEBUG       => 5

=cut

use base qw(Class::Accessor::Fast);

use Carp;
use Module::Pluggable require => 1;

use Wiz qw(get_hash_args);
use Wiz::Constant qw(:common);
use Wiz::DateTime;

use Wiz::ConstantExporter {
    FATAL       => 0,
    ERROR       => 1,
    WARN        => 2,
    INFO        => 3,
    LOGGING     => 4,
    DEBUG       => 5,
};

use Wiz::ConstantExporter [qw(
    get_level_no
)];

__PACKAGE__->mk_accessors(qw(stack_dump conf));

my %default = (
    path            => undef,
    log_base_dir    => undef,
    base_dir        => undef,
    level           => ERROR,   
    stdout_level    => ERROR,
    stderr_level    => ERROR,
    autoflush       => TRUE,
    simple          => FALSE,
);

our @CONFS = keys %default;

=head1 METHOD

=head2 CONSTRUCTOR

=head3 $log = new(\%params)

=head3 $log = new(%params)

Constructor.
You can specify how to output log with hash, hashref.

=head4 stdout,stderr

 level : output level

=head4 file

 path  : output file name
 level : output level
 open  : whether the file is opened initially or not.
         Default is TRUE, meaning the file is opened initially. When false, the file isn't opened, 
         and will be opened manually with calling openfile() method.

=head4 mail

 _conf : file name which contains configurations for Wiz::Mail::new.
         It is written like this. 
 
         {
            Host          => 'host1.wiz.net',
            Hello         => 'host1.wiz.net',
            Timeout       => 60,
         }
 
 config : hashref containing configuration info. Its format is the same with above.
 level  : output level

Both '_conf' and 'config' can be specified. 'config' can be used to define additional information
which is not configured in '_conf'.
In case both '_conf' and 'config' define the same key, it is overwritten with the one in 'config'.

See Wiz::Mail for more detail.
 
=head4 syslog

 ident    : Program name passed into the log.
 facility : Facility.
 level    : Output level.
 open     : Default is TRUE, indicating the file is opened initially. When false, the file isn't opened, 
 and will be opened manually with openfile() method.           
         
You can specify 'facility' and 'level', but those are used only deciding whether
this module ITSELF will output or not.
Even if decided to output, a message won't always be written to syslog, according to syslog.conf.

=cut

sub new {
    my $self = shift;
    my $conf = get_hash_args(@_);
    $conf->{log_base_dir} and $conf->{base_dir} = $conf->{log_base_dir};
    _pre_process_conf($conf);
    my $log_objects = { conf => $conf, };
    for my $plugin ($self->plugins) {
        my ($name) = $plugin =~ /.*::(.*)$/;
        $name eq 'Base' and next;
        defined $conf->{lc $name} or next;
        $log_objects->{__obj__}{$name} = $plugin->new($conf->{lc $name});
    }
    $log_objects->{simple} = $conf->{simple} || FALSE;
    return bless $log_objects, $self;
}

=head2 SETTING/GETTING indivisual log settings

=head3 set_level($type, $level)

Sets log level for indivisual log type specified by $type.

=cut

sub set_level {
    my ($self, $type, $level) = @_;
    
    if (defined $self->{__obj__}{$type}) { 
        $self->{__obj__}{$type}{level} = _convert_to_level_no($level);
    }
}

=head3 $level = get_level($type)

Gets current log level of log type specified by $type.

=cut

sub get_level {
    my ($self, $type) = @_;
    return (defined $self->{__obj__}{$type}) ? $self->{__obj__}{$type}{level} : undef;
}

=head2 WRITING TO LOG

There are 6 methods for log output, corresponding to log levels.

Method names indicate its log levels.

=head3 fatal($message)

=cut

sub fatal {
    my $self = shift;
    my ($msg, $caller) = @_;
    $self->_put_log(\$msg, FATAL, $caller);
}

=head3 error($message)

=cut

sub error {
    my $self = shift;
    my ($msg, $caller) = @_;
    $self->_put_log(\$msg, ERROR, $caller);
}

=head3 warn($message)

=cut

sub warn {
    my $self = shift;
    my ($msg, $caller) = @_;
    $self->_put_log(\$msg, WARN, $caller);
}

=head3 info($message)

=cut

sub info {
    my $self = shift;
    my ($msg, $caller) = @_;
    $self->_put_log(\$msg, INFO, $caller);
}

=head3 logging($message)

=cut

sub logging {
    my $self = shift;
    my ($msg, $caller) = @_;
    $self->_put_log(\$msg, LOGGING, $caller);
}

=head3 debug($message)

=cut

sub debug {
    my $self = shift;
    my ($msg, $caller) = @_;
    $self->_put_log(\$msg, DEBUG, $caller);
}

sub write {
    my $self = shift;
    my ($lv, $msg, $caller) = @_;
    if ($lv !~ /^\d*$/) {
        $lv = get_level_no($lv);
    }
    $self->_put_log(\$msg, $lv, $caller);
}

=head3 open()

In case 'file' is specified as destination, opens file.
Basically, openfile() is not necessary unless 'open => FALSE' is specified explicitly 
in 'file' configuration. 

=cut

sub open {
    my $self = shift;
    $self->_file->open;
}

=head3 close()

In case 'file' is specified as destination, close file.
closefile is not necessary unless you want to close file explicitly, because the file 
will be closed automatically in DESTROY.

=cut

sub close {
    my $self = shift;
    $self->_file->close;
}

=head3 flush()

Sync disk writing of log data. Usually using 'flush' is enough.(Windows doesn't have 'sync')
Actually, write delay will occur anyway because of disk cache.  

=cut

sub flush {
    my $self = shift;
    for (keys %{$self->{__obj__}}) { $self->{__obj__}{$_}->flush; }
}

=head3 sync()

=cut

sub sync {
    my $self = shift;
    for (keys %{$self->{__obj__}}) { $self->{__obj__}{$_}->sync; }
}

=head3 autoflush()

If TRUE, automatically flushes every time writing disk occurs.
Default is FALSE.

=cut

sub autoflush {
    my $self = shift;
    for (keys %{$self->{__obj__}}) { $self->{__obj__}{$_}->autoflush; }
}

=head2 DESTRUCTOR

In case 'file' or 'syslog' specified in configuration, closes those outputs by calling 
closefile() or closesyslog().

=cut


=head2 FOR BACKWARD COMPATIBILITY

=cut

=head3 path

Setter/getter for log file path.

=cut

sub path {
    my ($self, $path) = @_;
    
    defined $path or return $self->_file->{path};
    $self->_file->{path} = $path;
}

=head3 level

Setter/getter for file log level.

=cut

sub level {
    my ($self, $level) = @_;
    defined $level or return $self->get_level('File');
    $self->set_level('File', $level);
}

=head3 stdout($flag)

Setter/getter for log output for stdout.

=cut

sub stdout {
    my ($self, $flag) = @_;
    defined $flag or return $self->_stdout->{_output_flag} || FALSE;
    $self->_stdout->{_output_flag} = $flag;
}

=head3 stderr($flag)

Setter/getter for log output for stderr.

=cut

sub stderr {
    my ($self, $flag) = @_;
    defined $flag or return $self->_stderr->{_output_flag} || FALSE;
    $self->_stderr->{_output_flag} = $flag;
}

=head3 stdout_level

Setter/getter for log output level for stdout.

=cut

sub stdout_level {
    my ($self, $level) = @_;
    defined $level or return $self->get_level('Stdout');  
    $self->set_level('Stdout', $level);
}

=head3 stderr_level

Setter/getter for log output level for stderr.

=cut

sub stderr_level {
    my ($self, $level) = @_;
    defined $level or return $self->get_level('Stderr');  
    $self->set_level('Stderr', $level);
}

=head3 set_std($flag)

Enables/disables log output for stdout and stderr simultaneously.

=cut

sub set_std {
    my ($self, $flag) = @_;
    $self->set_stdout($flag);
    $self->set_stderr($flag);
}

=head3 set_stdout($flag)

Enables/disables log output for stdout.

=cut

sub set_stdout {
    my ($self, $flag) = @_;
    $self->_stdout->{_output_flag} = $flag;
}

=head3 set_stderr

Enables/disables log output for stderr.

=cut

sub set_stderr {
    my ($self, $flag) = @_;
    $self->_stderr->{_output_flag} = $flag;
}

=head3 set_stdout_level

Set log level for stdout.

=cut

sub set_stdout_level {
    my ($self, $level) = @_;
    $self->set_level('Stdout', $level); 
}

=head3 set_stderr_level

Set log level for stderr.

=cut

sub set_stderr_level {
    my ($self, $level) = @_;
    $self->set_level('Stderr', $level);
}

##----------  private method -----------##

sub _convert_to_level_no {
    my $level = shift;
    defined $level or return;    
    return ($level =~ /^\d*$/) ? $level : get_level_no($level);
}

sub get_level_no {
    my $str = shift;

    if (lc $str eq 'fatal') { return FATAL; }
    elsif (lc $str eq 'error') { return ERROR; }
    elsif (lc $str eq 'warn') { return WARN; }
    elsif (lc $str eq 'info') { return INFO; }
    elsif (lc $str eq 'logging') { return LOGGING; }
    elsif (lc $str eq 'debug') { return DEBUG; }

    return undef;
}

sub _put_log {
    my $self = shift;
    my ($r_log_msg, $lv, $caller) = @_;

    defined $caller or $caller = [ caller(1) ];

    my $lbl = '';
    if    ($lv == FATAL)   { $lbl = '[ FATAL ]';   }
    elsif ($lv == ERROR)   { $lbl = '[ ERROR ]';   }
    elsif ($lv == WARN )   { $lbl = '[ WARN ]';    }
    elsif ($lv == INFO )   { $lbl = '[ INFO ]';    }
    elsif ($lv == LOGGING) { $lbl = '[ LOGGING ]'; }
    elsif ($lv == DEBUG)   { $lbl = '[ DEBUG ]';   }
        
    my $now = new Wiz::DateTime();
    my $appended_info = $self->{simple} ? '' : " ($caller->[1]:$caller->[2]) $now";
    my $msg = "$lbl $$r_log_msg$appended_info\n";
    my $stack_dump = undef; 
    if ($self->{conf}{stack_dump}) {
        for my $i (2..10) {
            my @caller = caller($i);
            if (@caller) {
                $stack_dump .= "\t$caller[3]";
                $self->{simple} or $stack_dump .= "($caller[1]:$caller[2])";
                $stack_dump .= "\n";
            }
        }
    }

    my $logs = $self->{__obj__};
    for my $type (keys %$logs) {
        eval {
            $logs->{$type}->output($msg, $stack_dump, $lv);
        };
        if ($@) {
            my $time = localtime;
            print STDOUT 
                "[$time] Failed to write to $type : $@\n";   
        }   
    }    
}

sub _pre_process_conf {
    my $conf = shift;
    no warnings 'uninitialized';
    if (defined $conf->{path}) {
        if (defined $conf->{base_dir}) {
            $conf->{base_dir} =~ s/\/*$//;
            $conf->{file}{path} = $conf->{base_dir} . '/' . $conf->{path};
        }
        else {
            $conf->{file}{path} = $conf->{path};
        }
        defined $conf->{level} or $conf->{level} = ERROR;
        $conf->{file}{level} = _convert_to_level_no($conf->{level});
        $conf->{file}{autoflush} = $conf->{autoflush};
    }

    for (qw(stdout stderr)) {
        if ($conf->{$_}) {
            unless (ref $conf->{$_}) {
                my $c = {
                    _output_flag    => TRUE,
                };
                $c->{level} = defined $conf->{level} ?
                    _convert_to_level_no($conf->{level}) :
                    _convert_to_level_no($conf->{$_});
                $conf->{$_} = $c;
            }
        }
    }
}

sub _file {
    $_[0]->{__obj__}{File};   
}

sub _stdout {
    $_[0]->{__obj__}{Stdout};   
}

sub _stderr {
    $_[0]->{__obj__}{Stderr};   
}

=head1 SEE ALSO

L<Wiz::Log::Controller>

=head1 AUTHOR

Egawa Takashi, C<< <egawa.takashi@adways.net> >>

[Base idea & modify] Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

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
