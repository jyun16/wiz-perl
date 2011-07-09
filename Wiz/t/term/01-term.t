#!/usr/bin/perl

use lib qw(../../lib);

use Wiz::Constant qw(:common);
use Wiz::Test qw(no_plan);
use Wiz::Term qw(:all);
use Wiz::Term::Menu qw(:all);

use Data::Dumper;

#$ENV{WIZ_TERM_COLOR_MODE} = FALSE;

my %conf = (
    edit_target_file => '/tmp/wiz_term_menu_test.dat',
);

sub main {
    my $menu = create_main_menu();
    $menu->submenu(sub => create_sub_menu());
    $menu->start;
    return 0;
}

sub create_main_menu {
    my $menu = new Wiz::Term::Menu(
        title => ' --- MAIN MENU --- ',
        author => 'JN'
    );
    $menu->display(sub {
pn '1. menu-1', YELLOW;
pn '2. menu-2', YELLOW;
pn '3. menu-3', YELLOW;
pn 'input. input mode', YELLOW;
pn 'v. vi $conf{edit_target_file}', GREEN;
pn 'edit', YELLOW;
pn 'sub. goto the sub menu', YELLOW;
    });

    $menu->submenu(
        edit    => create_recursion_edit_term('conf/hoge')
    );
    $menu->dispatcher(
        1       => sub {
            my $self = shift;
            $self->message('MENU-1');
        },
        2       => sub {
            my $self = shift;
            $self->message('MENU-2');
        },
        3       => sub {
            my $self = shift;
            $self->message('MENU-3');
        },
        err     => sub {
            my $self = shift;
            $self->error_message('ERROR-TEST');
            $self->{prompt} = undef;
        },
        input   => sub {
            my $self = shift;
            $self->message('INPUT-TEST');

            if ($self->{input} eq '.') {
                $self->normal_mode;
            }
            else {
                $self->input_mode;
            }

            $self->prompt(sub {
                my $self = shift;
                p "[$self->{input}]: ";
            });
        },
        v       => sub {
            my $self = shift;
            $self->edit($conf{edit_target_file});
        }
    );
    return $menu;
}

sub create_sub_menu {
    my $menu = new Wiz::Term::Menu(
        title => ' --- SUB MENU --- ',
        author => 'JN'
    );
    $menu->display(sub {
pn '1. submenu-1', YELLOW;
pn '2. submenu-2', YELLOW;
pn '3. submenu-3', YELLOW;
pn 'sub. goto the sub sub menu', YELLOW;
pn 'back. back to the main menu', YELLOW;
    });
    $menu->dispatcher(
        1       => sub {
            my $self = shift;
            $self->error_message('SUBMENU-1'),
        },
        2       => sub {
            my $self = shift;
            $self->message('SUBMENU-2'),
        },
        3       => sub {
            my $self = shift;
            $self->message('SUBMENU-3'),
        },
    );
    $menu->submenu(sub => create_sub_sub_menu());
    return $menu;
}

sub create_sub_sub_menu {
    my $menu = new Wiz::Term::Menu(
        title => ' --- SUBSUB MENU --- ',
        author => 'JN'
    );
    $menu->display(sub {
pn '1. sub-submenu-1', YELLOW;
pn '2. sub-submenu-2', YELLOW;
pn '3. sub-submenu-3', YELLOW;
pn 'main. go to the main menu', YELLOW;
pn 'back. back to the sub menu', YELLOW;
    });
    $menu->dispatcher(
        1       => sub {
            my $self = shift;
            $self->message('SUBSUBMENU-1'),
        },
        2       => sub {
            my $self = shift;
            $self->message('SUBSUBMENU-2'),
        },
        3       => sub {
            my $self = shift;
            $self->message('SUBSUBMENU-3'),
        },
        main    => sub {
            my $self = shift;
            $self->jump(qw(root));
        }
    );
    return $menu;
}

skip_confirm(2) and exit main;
