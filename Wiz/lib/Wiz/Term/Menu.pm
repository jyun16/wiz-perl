package Wiz::Term::Menu;

use strict;
use warnings;

=head1 NAME

Wiz::Term::Menu

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use base qw(Class::Accessor::Fast);

use Carp;
use Data::Dumper;

use Wiz qw(get_hash_args);
use Wiz::Term qw(:all);
use Wiz::Constant qw(:common);
use Wiz::Util::String qw(trim_sp);
use Wiz::Util::Array qw(args2array);
use Wiz::Util::Hash qw(hash_access_by_list);
use Wiz::Util::File qw(filename ls :const);

no warnings 'uninitialized';

$Data::Dumper::Deparse = 1;

=head1 EXPORTS

=cut

use Wiz::ConstantExporter [qw(create_recursion_edit_term)];

our $AUTOLOAD;

my %default = (
    clear_command   => '/usr/bin/clear',
    editor          => 'vi',
    author          => '',
    title           => '',
    mode            => '',
    default_mode    => '',
    internal_mode   => '',
    input           => '',
    message         => '',
    error_message   => '',
    parent_menu     => undef,
    display         => undef,
    prompt          => undef,
    listen          => undef,
    dispatcher      => undef,
    stash           => undef,
);

__PACKAGE__->mk_accessors(keys %default);

sub AUTOLOAD {
    my $self = shift;

    $AUTOLOAD =~ s/^.*:://;
    if ($AUTOLOAD =~ /^dispatch_(.*)/) {
        $self->print_error_message("unknown command $1");
    }
}

=head1 CONSTRUCTOR

=cut 

sub new {
    my $self = shift;
    my $args = get_hash_args(@_);
    my $instance = bless { 
        map { $_ => $args->{$_} ? $args->{$_} : $default{$_} } keys %default
    }, $self;
    $instance->{dispatcher} = {
        q       => \&_quit,
        quit    => \&_quit,
        back    => sub { shift->back2parent },
    };
    $instance->{display} = \&_display;
    $instance->{prompt} = \&_prompt;
    $instance->{listen} = \&_listen;
    $instance->{stash} = {};
    $instance->{menu_tree} = {
        root  => { __menu_obj => $instance },
    };
    $instance->{cur_menu_tree_pos} = $instance->{menu_tree}{root};
    return $instance;
}

=head1 METHODS

=cut

sub start {
    my $self = shift;

    if ($self->{mode}) { $self->dispatch($self->{mode}); }
    elsif ($self->{default_mode}) {
        $self->{mode} = $self->{default_mode};
        $self->dispatch($self->{default_mode});
    }
    while(1) {
        $self->clear;
        $self->header;
        $self->call_display;
        $self->print_message;
        $self->print_error_message;
        $self->call_prompt;
        $self->call_listen;
    }
}

sub header {
    my $self = shift;

    double_line CYAN;
    if ($self->{title} ne '' or $self->{author} ne '') {
        $self->{title} and pn $self->{title}, RED;
        if ($self->{author}) {
            my $author = "powered by $self->{author}";
            pn ' ' x ($Wiz::Term::WIDTH - length $author) . $author , CYAN;
        }
        line CYAN;
    }
}

sub call_display {
    my $self = shift;
    $self->{display}->($self);
}

sub call_prompt {
    my $self = shift;
    line CYAN;
    $self->{prompt} ||= \&_prompt;
    $self->{prompt}->($self);
}

sub call_listen {
    my $self = shift;
    $self->{listen}->($self);
}

sub print_message {
    my $self = shift;
    if ($self->{message} ne '') {
        line CYAN;
        pn "$self->{message}";
    }
    $self->{message} = '';
}

sub print_error_message {
    my $self = shift;
    if ($self->{error_message} ne '') {
        line CYAN;
        pn "[ ERROR ] $self->{error_message}", RED;
    }
    $self->{error_message} = '';
}

sub dispatch {
    my $self = shift;
    my ($name) = @_;
    if ($self->{dispatcher}{$name}) { $self->{dispatcher}{$name}->($self); }
}

sub dispatcher {
    my $self = shift;
    my $args = get_hash_args(@_);
    for (keys %$args) { $self->{dispatcher}{$_} = $args->{$_}; }
}

sub append_message {
    my $self = shift;
    $self->{message} .= shift;
}

sub append_error_message {
    my $self = shift;
    $self->{error_message} .= shift;
}

sub submenu {
    my $self = shift;
    my ($name, $submenu) = @_;

    ref $submenu or return;
    my %tree = map { $_ => $submenu->{cur_menu_tree_pos}{$_} }
        keys %{$submenu->{cur_menu_tree_pos}};
    $tree{__menu_obj} = $submenu;
    $self->{cur_menu_tree_pos}{$name} = \%tree;
    _menutree_replace($self->{menu_tree}, $submenu->{menu_tree});
    $submenu->{parent} = $self;
    $self->{dispatcher}{$name} = sub {
        $submenu->start;
    }
}

sub _menutree_replace {
    my ($base, $target) = @_;
    for (keys %$target) {
        if ($_ eq '__menu_obj') { $target->{__menu_obj}{menu_tree} = $base; }
        else { _menutree_replace($base, $target->{$_}); }
    }
}

sub jump {
    my $self = shift;
    my $target = _jump($self->{menu_tree}, args2array(@_));
    $self->{mode} = '';
    $target->{mode} = '';
    return $target->start;
}

sub relative_jump {
    my $self = shift;
    my $target = _jump($self->{cur_menu_tree_pos}, args2array(@_));
    $self->{mode} = '';
    $target->{mode} = '';
    return $target->start;
}

sub back2parent {
    my $self = shift;
    if ($self->{parent}) {
        $self->{mode} = '';
        $self->{parent}{mode} = '';
        $self->{parent}->start;
    }
}

sub edit {
    my $self = shift;
    my ($path) = @_;
    system("$self->{editor} $path");
}

sub editor {
    my $self = shift;
    my ($editor) = @_;
    defined $editor and $self->{editor} = $editor;
    return defined $self->{editor} ? $self->{editor} : $ENV{EDITOR};
}

sub mode_jump {
    my $self = shift;
    my ($mode) = @_;

    $self->dispatch($mode);
    $self->mode($mode);
    $self->{_loop_ignore} = 1;
}

sub clear_stash {
    my $self = shift;
    $self->{stash} = {};
}

sub clear {
    my $self = shift;
    system $self->{clear_command};
}

#----[ static ]-------------------------------------------------------
use constant {
    TYPE_DIR    => 1,
    TYPE_FILE   => 2,
};

sub create_recursion_edit_term {
    my ($path, $option) = @_;

    -d $path or return;
    return _create_recursion_edit_term($path, $option);
}

sub _create_recursion_edit_term {
    my ($path, $option) = @_;

    -d $path or return;
    my $menu = new Wiz::Term::Menu(
        title   => "$option->{title} :$path",
        author  => $option->{author},
    );
    my @display = ();
    my $dirs = ls $path, LS_DIR;
    for (@$dirs) {
        my $n = filename $_;
        push @display, [ $n, $_, TYPE_DIR ];
        $menu->submenu($n => _create_recursion_edit_term($_, $option));
    }
    my $files = ls $path, LS_FILE;
    for (@$files) { push @display, [ (filename $_), $_, TYPE_FILE ]; }
    $menu->display(sub {
        pn '..)', BLUE;
        for (@display) { pn $_->[0], ($_->[2] == TYPE_DIR ? BLUE : WHITE); }
    });
    my %dispatcher = ('..' => sub { shift->back2parent; });
    for my $d (@display) {
        if ($d->[2] == TYPE_FILE) {
            $dispatcher{$d->[0]} = sub { shift->edit($d->[1]); }
        }
        else {
            $dispatcher{$d->[0]} = sub { shift->relative_jump($d->[0]); }
        }
    }
    $menu->dispatcher(\%dispatcher);
    return $menu;
}

sub input_mode {
    my $self = shift;
    $self->{internal_mode} = 'input';
}

sub normal_mode {
    my $self = shift;
    $self->{internal_mode} = '';
}

#----[ private ]------------------------------------------------------
sub _jump {
    my ($tree, $list) = @_;
    my @l = @$list;
    while (my $d = shift @l) { return _jump($tree->{$d}, \@l); }
    return $tree->{__menu_obj};
}

sub _display {
    my $self = shift;
    pn 'DISPLAY MENU...', YELLOW;
}

sub _prompt {
    my $self = shift;
    p "menu[$self->{mode}]: ";
}

sub _listen {
    my $self = shift;

    no strict 'refs';
    while(<>) {
        s/\r?\n$//;
        $_ = trim_sp($_);

        if ($self->{_loop_ignore}) {
            $self->{_loop_ignore} = 0;
            next;
        }

        if ($self->{internal_mode} eq 'input') {
            if ($_ eq '') {
                $self->normal_mode;
                $self->back2parent;
            }
            else {
                $self->{input} = $_;
                $self->dispatch($self->{mode});
            }
        }
        else {
            $self->{mode} = $_;
            $self->dispatch($_);
        }
        last;
    }
}

sub _quit {
    my $self = shift;
    exit;
}

=head1 FUNCTIONS

=cut

#----[ static ]-------------------------------------------------------
#----[ private static ]-----------------------------------------------

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

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
