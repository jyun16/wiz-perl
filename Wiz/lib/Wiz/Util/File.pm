package Wiz::Util::File;

use strict;
use warnings;

no warnings 'uninitialized';

=head1 NAME

Wiz::Util::File

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Cwd;
use Carp;
use Clone qw(clone);
use File::Basename;
use File::Mirror;
use File::Path;
use File::Copy;
use IO::Handle;
use YAML::Syck;

use Wiz::DateTime;
use Wiz::Constant qw(:common);
use Wiz::Config qw(load_config_files);
use Wiz::Util::String qw(trim_quote trim_sp split_csv);
use Wiz::Util::Hash qw(
    hash_access_by_list override_hash convert_interactive_hash
    hash_relatively_access cleanup_interactive_hash
    hash_anchor_alias
);
use Wiz::Util::Tree qw(
    dependency_tree
    dependency_sequence
);

=head1 EXPORTS

 const = { 
     LS_FILE            => 1,
     LS_DIR             => 2,
     LS_FILE_AND_DIR    => 3,
     LS_ABS             => 4,
     LS_ALL             => 8,
 },
 
 sub => {
     file_write
     file_append
     file_read
     file_read2str
     file_flush_write
     file_flush_append
     file_sync_write
     file_sync_append
     file_data_eval
     fix_path
     config_tree
     extended_config_tree
     properties
     get_device_no
     get_inode
     get_permission
     get_link_number
     get_uid
     get_gid
     get_size
     get_last_access
     get_last_modify
     get_create_time
     get_absolute_path
     cwd
     mkdir
     rm
     rm_empty_dir
     cp
     mv
     chmod
     chmod_r
     ln
     ln_s
     ls
     ls_r
     touch
     touch_a
     touch_m
     dirname
     filename
     rename
     replace_copy
     cleanup
     parse_csv_file
 }
 
=cut

use Wiz::ConstantExporter [qw(
    file_write
    file_append
    file_read
    file_read2str
    file_flush_write
    file_flush_append
    file_sync_write
    file_sync_append
    file_data_eval
    fix_path
    config_tree
    extended_config_tree
    config_path_tree
    properties
    get_device_no
    get_inode
    get_permission
    get_link_number
    get_uid
    get_gid
    get_size
    get_last_access
    get_last_modify
    get_create_time
    get_absolute_path
    cwd
    cp
    mv
    chmod
    chmod_r
    ln
    ln_s
    mkdir
    rm
    rm_empty_dir
    touch
    touch_a
    touch_m
    ls
    ls_r
    dirname
    filename
    rename
    replace_copy
    cleanup
    parse_csv_file
)];

use Wiz::ConstantExporter {
    LS_FILE                         => 1,
    LS_DIR                          => 2,
    LS_FILE_AND_DIR                 => 3,
    LS_ABS                          => 4,
    LS_ALL                          => 8,
    RENAME_IGNORE_DIRECTORY         => 1,
};

use constant {
    NOT_IGNORE          => 0,
    IGNORE              => 1,
    IGNORE_ARRAY        => 2,
};

=head1 FUNCTIONS

=head2 file_write($path, $data or \$data)

=cut

sub file_write {
    my ($path, $data) = @_;

    my $ope = -f $path ? '+<' : '>';
    open my $file, $ope, $path or confess "can't open $path ... $!\n";
    flock $file, 2;
    if ($ope eq '+<') { seek $file, 0, 0; }
    print $file ref $data ? $$data : $data;
    if ($ope eq '+<') { truncate $file, tell($file); }

    close $file;
}

=head2 file_append($path, $data or \$data)

=cut

sub file_append {
    my ($path, $data) = @_;

    open my $file, '>>', $path or confess "can't open $path ... $!\n";
    flock $file, 2;
    print $file ref $data ? $$data : $data;
    close $file;
}

=head2 @data or \@data = file_read($path)

=cut

sub file_read {
    my $path = shift;

    open my $file, '<', $path or confess "can't open $path ... $!\n";
    flock $file, 1;
    my @data = <$file>;
    chomp @data;
    close $file;

    return wantarray ? @data : \@data;
}

=head2 $data = file_read2str($path)

=cut

sub file_read2str {
    my $path = shift;

    local $/ = undef;
    open my $file, '<', $path or confess "can't open $path ... $!\n";
    flock $file, 1;
    my $data = <$file>;
    close $file;

    return $data;
}

=head2 file_flush_write($path, $data or \$data)

=cut

sub file_flush_write {
    my ($path, $data) = @_;
    _io_write($path, $data, -f $path ? '+<' : '>');
}

=head2 file_flush_append($path, $data or \$data)

=cut

sub file_flush_append {
    my ($path, $data) = @_;
    _io_write($path, $data, '>>');
}

=head2 file_sync_write($path, $data or \$data)

=cut

sub file_sync_write {
    my ($path, $data) = @_;
    _io_write($path, $data, -f $path ? '+<' : '>', TRUE);
}

=head2 file_sync_append($path, $data or \$data)

=cut

sub file_sync_append {
    my ($path, $data) = @_;
    _io_write($path, $data, '>>', TRUE);
}

=head2 $data = file_data_eval($path)

Returns hash and array tree data from the file written by perl.

=cut

sub file_data_eval {
    my ($path) = @_;
    -r $path or confess "can't read $path ($!)"; 
    my $data = do $path;
    $@ and confess $@;
    return $data;
}

=head2 $path = fix_path($cwd, $path)

 # /home/foo/bar
 fix_path('/home/foo', 'bar');
  
 # /home/foo/bar
 fix_path('/home/foo', './bar');
  
 # /home/foo/bar
 fix_path('/home/foo', '../bar');
  
 # /home/bar
 fix_path('/home/foo', '../bar');
  
 # /bar
 fix_path('/home/foo', '../../bar');

=cut

sub fix_path {
    my ($cwd, $path) = @_;
    $path =~ /^\// and return $path;
    $cwd = get_absolute_path($cwd);
    my @cwd = split /\//, $cwd;
    my ($b, $p) = ($path =~ /^([\.\/]*)(.*)/);
    $p =~ s/\/*$//;
    my $n = (() = $b =~ /\./g);
    if ($n % 2 == 0) {
        for (1..($n / 2)) { pop @cwd; }
    }
    @cwd == 0 and push @cwd, '';
    $p ne '' and push @cwd, $p;
    if (@cwd == 1) {
        $cwd[0] eq '' and return '/';
    }
    return join '/', @cwd;
}

=head2 $data = config_tree($path)

Returns a hash tree data of pdat and file name and directory name.

ex)

# directories
conf
    foo/bar.pdat
    xxx/yyy.pdat

foo/bar.pdat
    {
        blah => 'BLAH',
    }

xxx/yyy.pdat
    {
        zzz => 'ZZZ',
    }
 
 my $data = config_tree('/conf');
 
 # foo => {
 #     bar => {
 #         blah    => 'BLAH',
 #     },
 # },
 # xxx => {
 #     yyy => {
 #         zzz     => 'ZZZ',
 #     }
 # },
 print Dumper $data;

Caution: files have prefix '.' are ignored.

=cut

sub config_tree {
    my %ret = (); _config_tree(shift, \%ret);
}

sub _config_tree {
    my ($path, $ret) = @_;

    opendir my $dir, $path or confess "can't open $path ($!)";
    for my $t (grep !/^\.\.?/, readdir($dir)) {
        my $p = "$path/$t";
        if (-f $p) {
            $t =~ /(.*)\.(?:.*)$/;
            defined $1 and
                $ret->{$1} = Wiz::Config::load_config_files($p);
        }
        else {
            $ret->{$t} = {};
            _config_tree($p, $ret->{$t});
        }
    }
    closedir $dir;
    return $ret;
}

=head2 $data = extended_config_tree($path, $use_alias or undef)

=cut

sub extended_config_tree {
    my ($ret, $extends) = ({}, []);
    _extended_config_tree(shift, $ret, $extends);
    my $use_alias = shift;
    convert_interactive_hash($ret);
    for my $extend (@$extends) {
        my $ex = $$extend->{_extends};
        delete $$extend->{_extends};
        if (ref $ex) {
            my $cnt = 0;
            for (@$ex) {
                if ($cnt == $#$ex) { $_ =~ s/^\.\.\///; _extended_config_tree_extend($extend, $_, TRUE); }
                else { _extended_config_tree_extend($extend, $_, FALSE); }
                $cnt++;
            }
        }
        else { _extended_config_tree_extend($extend, $ex, TRUE); }
    }
    cleanup_interactive_hash($ret);
    return $use_alias ? hash_anchor_alias($ret) : $ret;
}

sub _extended_config_tree_extend {
    my ($extend, $ex, $cleanup) = @_;

    my $super = clone hash_relatively_access($$extend, $ex);
    if ($super) {
        my $bu = clone $$extend;
        if ($cleanup) {
            cleanup_interactive_hash($bu);
            cleanup_interactive_hash($super);
        }
        %$$extend = %$super;
        _override_hash_without_parent_hash($$extend, $bu);
    }
}

sub _override_hash_without_parent_hash {
    my ($original, $override) = @_;

    if (ref $original eq 'HASH') {
        for (keys %{$override}) {
            $_ eq '__parent_hash__' and next;
            if (ref $override->{$_} eq 'HASH') {
                defined $original->{$_} or $original->{$_} = {};
                %{$override->{$_}} or $original->{$_} = {};
                _override_hash_without_parent_hash($original->{$_}, $override->{$_});
            }
            else { $original->{$_} = $override->{$_}; }
        }
    }
    return $original;
}

sub _extended_config_tree {
    my ($path, $ret, $extends) = @_;

    opendir my $dir, $path or confess "can't open $path ($!)";
    my $local_extends = {};
    my $dependency = {};
    for my $t (grep !/^\.\.?/, readdir($dir)) {
        my $p = "$path/$t";
        if (-f $p) {
            $t =~ /(.*)\.(?:.*)$/;
            if (defined $1) {
                my $data = Wiz::Config::load_config_files($p);
                if ($data) {
                    for (keys %$data) {
                        if ($_ eq '_extends') {
                            my @x = split /\//, $data->{$_};
                            if (@x == 2) {
                                push @{$dependency->{$1}}, pop @x;
                            }
                            $local_extends->{$1} = \$data;
                        }
                    }
                    $ret->{$1} = $data;
                }
            }
        }
        else {
            $ret->{$t} = {};
            _extended_config_tree($p, $ret->{$t}, $extends);
        }
    }
    my $sequence = dependency_sequence($dependency);
    for my $s (@$sequence) {
        for (@$s) {
            push @$extends, $local_extends->{$_};
            delete $local_extends->{$_};
        }
    }
    for (keys %$local_extends) { push @$extends, $local_extends->{$_}; }
    closedir $dir;
    return $ret;
}

=head2 $data = config_tree($path)

Returns hash data of config file path in a directory $path.

=cut

sub config_path_tree {
    my ($path) = @_;

    my %ret = ();
    _config_path_tree($path, \%ret);
    return \%ret;
}

sub _config_path_tree {
    my ($path, $ret) = @_;

    opendir my $dir, $path or confess "can't open $path ($!)";
    for my $t (grep !/^\.\.?$/, readdir($dir)) {
        $t =~ /^\./ and next;
        my $p = "$path/$t";
        if (-f $p) {
            $t =~ /(.*)\.(?:.*)$/;
            $ret->{$1} = {
                path    => $p,
            };
        }
        else {
            $ret->{$t} = {
                path    => $p,
            };
            _config_path_tree($p, $ret->{$t});
        }
    }
    closedir $dir;
}

=head2 $properties = properties($path)

 hoge = HOGE
 fuga = FUGA
 # comment 1
     # comment 2
 foo = 'FOO'
 bar = "BAR"
 nonvalue1 = #whoooooooooo
 nonvalue2 =

When you specify the above data in a file, this method output the following data.

 {
     hoge        => 'HOGE',
     fuga        => 'FUGA',
     foo         => 'FOO',
     bar         => 'BAR',
     nonvalue1   => '',
     nonvalue2   => '',
 }

It's a simple.

=cut

sub properties {
    my $path = shift;

    open my $data, '<', $path or confess "can't open $path ($!)";
    my %param = ();
    while (<$data>) {
        chomp;
        /^\s*#/ and next;
        my ($key, $value) = split /=/;
        defined $value or $value = '';
        trim_sp(\$key);
        trim_quote(\$key);
        trim_sp(\$value);
        trim_quote(\$value);
        $value =~ /^([^#]*)/;
        $param{$key} = $1;
    }
    close $data;
    return \%param;
}

=head2 $dev_no = get_device_no($path)

=cut

sub get_device_no { (stat shift)[0]; }

=head2 $inode = get_inode($path)

=cut

sub get_inode { (stat shift)[1]; }

=head2 $permission = get_permission($path)

=cut

sub get_permission { (stat shift)[2]; }

=head2 $link_number = get_link_number($path)

=cut

sub get_link_number { (stat shift)[3]; }

=head2 $uid = get_uid($path)

=cut

sub get_uid { (stat shift)[4]; }

=head2 $gid = get_gid($path)

=cut

sub get_gid { (stat shift)[5]; }

=head2 $size = get_size($path)

=cut

sub get_size { (stat shift)[7]; }

=head2 $last_access = get_last_access($path)

=cut

sub get_last_access { my $d = new Wiz::DateTime; $d->set_epoch((stat shift)[8]); return $d; }

=head2 $last_modify = get_last_modify($path)

=cut 

sub get_last_modify { my $d = new Wiz::DateTime; $d->set_epoch((stat shift)[9]); return $d; }

=head2 $create_time = get_create_time($path)

=cut

sub get_create_time { my $d = new Wiz::DateTime; $d->set_epoch((stat shift)[10]); return $d; }

=head2 $absolute_path =  get_absolute_path($path, $cwd)

return absolute path of $path

=cut

sub get_absolute_path {
    my ($path, $cwd) = @_;

    $cwd ||= cwd;
    if ($path =~ m#^/#) { return $path; }
    elsif ($path =~ /^\.\./) {
        my $cnt = $path =~ s#\.\.\/##g;
        $cwd =~ s#(/[^/]*){$cnt}$##;
        return "$cwd/$path";
    }
    elsif ($path =~ /^\./) {
        $path =~ s/^\./$cwd/;
        return $path;
    }
    else { return "$cwd/$path"; }
}

=head2 $cwd = cwd

=cut

{
    no warnings 'redefine';
    sub cwd { return Cwd::cwd; }
}

=head2 cp(@src_path, $dest_path)

=cut

sub cp { mirror @_; }

=head2 mv(@src_path, $dest_path)

=cut

sub mv { move @_; }

=head2 chmod($permit, $path)

=cut

sub chmod {
    my ($permit, $path) = @_;

    my $name = filename $path;
    if ($name =~ /\*/) {
        my $dirname = dirname $path;
        opendir my $dir, $dirname or confess "can't open $dirname ($!)";

        $name =~ s/([\.])/\\$1/g;
        $name =~ s/\*/\.\*/g;

        for my $t (grep !/^\.\.?/, readdir $dir) {
            $t =~ /$name/ and
                CORE::chmod $permit, "$dirname/$t" or confess "can't chmod $dirname/$t ($!)";
        }
        closedir $dir;
    }
    else {
        CORE::chmod $permit, $path or confess "can't chmod $path ($!)";
    }
}

=head2 chmod_r($permit, $path)

=cut

sub chmod_r {
    my ($permit, $path) = @_;

    my $name = filename $path;
    if ($name =~ /\*/) {
        my $dirname = dirname $path;

        $name =~ s/([\.])/\\$1/g;
        $name =~ s/\*/\.\*/g;

        for (ls_r $dirname) {
            /$name/ and CORE::chmod $permit, $_ or confess "can't chmod $_ ($!)";
        }
    }
    else {
        for (ls_r $path) {
            CORE::chmod $permit, $_ or confess "can't chmod $path ($!)";
        }
    }
}

=head2 ln($target, $link)

create the hard link from $target to $link

=cut

sub ln {
    my ($target, $link) = @_;
    link $target, $link;
}

=head2 ln_s($target, $link)

create the symbolic link from $target to $link

=cut

sub ln_s {
    my ($target, $link) = @_;
    symlink $target, $link;
}

=head2 mkdir($path)

=cut

sub mkdir { mkpath shift; }

sub rm {
    use File::Remove;
    File::Remove::rm \1, @_;
}

=head2 rm_empty_dir($path)

Recursively delete for empty directories

=cut

sub rm_empty_dir {
    my $path = shift;
    _rm_empty_dir($path) and rmdir $path;
}

sub _rm_empty_dir {
    my $path = shift;

    my $files = ls($path);
    my $delflag = TRUE;
    if (@$files) {
        $delflag = FALSE;
        for (@$files) {
            -d $_ or next;
            my $r = _rm_empty_dir($_);
            $r and rmdir $_;
        }
        $files = ls($path);
        @$files or rmdir $path;
    }

    return $delflag;
}

=head2 touch

touch $file_path;

=cut

sub touch {
    my $path = shift;
    my $date = _init_date(shift);

    -f $path or open my $file, '>>', $path or confess "can't open $path ... $!\n";
    defined $date and utime $date->epoch, $date->epoch, $path;
}

=head2 touch_a

change access time of $path

=cut

sub touch_a {
    my $path = shift;
    my $date = _init_date(shift);

    my $m_date = get_last_modify($path);
    -f $path or open my $file, '>>', $path or confess "can't open $path ... $!\n";
    utime $date->epoch, $m_date->epoch, $path;
}

=head2 touch_m

change last modify time of $path

=cut

sub touch_m {
    my $path = shift;
    my $date = _init_date(shift);

    my $a_date = get_last_access($path);
    -f $path or open my $file, '>>', $path or confess "can't open $path ... $!\n";
    utime $a_date->epoch, $date->epoch, $path;
}

=head2 @file_list or \@file_list = ls($path, $mode)

$mode: LS_DIR, LS_FILE, LS_FILE_AND_DIR(default), LS_ABS or LS_ALL

=cut

sub ls {
    my ($path, $mode) = @_;

    defined $path or $path = '.';
    -d $path or confess "$path is not directory";

    $mode ||= LS_FILE_AND_DIR;
    $mode & (~LS_ABS) or $mode |= LS_FILE_AND_DIR;
    $mode & (~LS_ALL) or $mode |= LS_FILE_AND_DIR;

    opendir my $dir, $path or confess "can't open $path ($!)";
    $path =~ s/\/*$//;
    my @ret = ();
    my $cwd = cwd;
    my $ignore = $mode & LS_ALL ? qr/^\.{1,2}$/ : qr/^\.{1,2}/;
    for my $target (grep !/$ignore/, readdir($dir)) {
        if (-d "$path/$target") { $mode & LS_DIR or next; }
        else { $mode & LS_FILE or next; }
        push @ret, $mode & LS_ABS ?
            get_absolute_path("$path/$target", $cwd) : "$path/$target";
    }
    closedir $dir;

    return wantarray ? @ret : \@ret;
}

=head2 @file_list or \@file_list = ls_r($path, $mode)

=cut

sub ls_r {
    my ($path, $mode) = @_;

    defined $path or $path = '.';
    -d $path or confess "$path is not directory.";

    $mode ||= LS_FILE_AND_DIR;
    $mode & (~LS_ABS) or $mode |= LS_FILE_AND_DIR;
    $mode & (~LS_ALL) or $mode |= LS_FILE_AND_DIR;

    my @ret = ();
    my $cwd = cwd;
    _ls_r($path, $cwd, \@ret, $mode);
    return wantarray ? @ret : \@ret;
}

=head2 $dirname = dirname($path)

get path of a directory from a file path

=cut

{
    no warnings 'redefine';
    sub dirname {
        my $path = shift;

        $path !~ /\/$/ and $path =~ s/[^\/]*$//;
        length $path > 1 and $path =~ s/\/$//;
        return $path;
    }
}

=head2 $filename = filename($path)

get a name of file from a file path

=cut

sub filename {
    my $path = shift;

    $path =~ /([^\/]*)$/;
    return $1;
}

=head2 renmae($target, $expr, $ignore_directory)

Rename files and directories.
If you want to ignore directory then $ignore_directyr = RENAME_IGNORE_DIRECTORY

Seiryo gives me some base idea. THX.

=cut

sub rename {
    my ($target, $expr, $ignore_directory) = @_;

    my @target = ls_r $target;
    my @replace_target = ();
    my @delete = ();
    for (@target) {
        my $t = $_;
        if (not $ignore_directory) {
            my $c = eval "\$t =~ $expr";
            -d $_ and $c and push @delete, $_;
        }
        push @replace_target, $t;
    }

    my $n = @target;
    for (my $i = 0; $i < $n; $i++) {
        my $dir = dirname $replace_target[$i];
        Wiz::Util::File::mkdir $dir;
        if ($target[$i] ne $replace_target[$i] and -f $target[$i]) {
            mv $target[$i], $replace_target[$i];
        }
    }

    for (@delete) { rm_empty_dir $_; }
}

=head2 replace_copy($src, $dest, $expr)

File copy with data replace to use regexp.

=cut

sub replace_copy {
    my ($src, $dest, $expr, $ignore) = @_;

    my $copy_func = ref $expr ? \&_replace_copy_multi : \&_replace_copy;
    if (-d $src) {
        $src = get_absolute_path $src;
        $src =~ s/\/$//; $dest =~ s/\/$//;
        my @src = ls_r $src;
        for (@src) {
            $_ =~ s/$src\///;
            $ignore and (grep /filename $_/, @$ignore) and next;
            if (-d "$src/$_") {
                Wiz::Util::File::mkdir "$dest/$_";
            }
            else {
                $copy_func->("$src/$_", "$dest/$_", $expr);
            }
        }
    }
    else {
        $ignore and (grep /filename $src/, @$ignore) and return;
        $copy_func->($src, $dest, $expr);
    }
}

sub _replace_copy {
    my ($src, $dest, $expr, $ignore) = @_;

    -d dirname($dest) or Wiz::Util::File::mkdir dirname($dest);
    open my $s, '<', $src or confess "can't open $src ($!)";
    open my $d, '>', $dest or confess "can't open $dest ($!)";
    while (my $l = <$s>) {
        eval "\$l =~ $expr";
        print $d $l;
    }
    close $d;
    close $s;
}

sub _replace_copy_multi {
    my ($src, $dest, $expr) = @_;

    -d dirname($dest) or Wiz::Util::File::mkdir dirname($dest);
    open my $s, '<', $src or confess "can't open $src ($!)";
    open my $d, '>', $dest or confess "can't open $dest ($!)";
    while (my $l = <$s>) {
        for my $e (@$expr) {
            eval "\$l =~ $e";
        }
        print $d $l;
    }
    close $d;
    close $s;
}


=head2 cleanup($dir, $expire)

Cleanup directory

$expire is second.

=cut

sub cleanup {
    my ($dir, $expire) = @_;
    opendir my $d, $dir or die "can't open directory $dir($!)";;
    for my $f (grep !/^\.\.?$/, readdir $d) {
        my $d = get_create_time("$dir/$f");
        if ($d->epoch + $expire < time) {
            unlink "$dir/$f";
        }
    }
    closedir $d;
}

# ----[ private static ]----------------------------------------------
sub _ls_r {
    my ($path, $cwd, $ret, $mode) = @_;

    $path =~ s/\/*$//;
    my $ignore = $mode & LS_ALL ? qr/^\.{1,2}$/ : qr/^\.{1,2}/;

    opendir my $dir, $path or confess "can't open $path ($!)";
    for my $target (grep !/$ignore/, readdir($dir)) {
        my $append = TRUE;
        if (-d "$path/$target") {
            $mode & LS_DIR or $append = FALSE;
            _ls_r("$path/$target", $cwd, $ret, $mode);
        }
        else { $mode & LS_FILE or next; }
        $append or next;
        push @$ret, $mode & LS_ABS ?
            get_absolute_path("$path/$target", $cwd) : "$path/$target";
    }
    closedir $dir;
}

sub _io_write {
    my ($path, $data, $ope, $sync_mode) = @_;

    open my $file, $ope, $path or confess "can't open $path ... $!\n";
    flock $file, 2;
    if ($ope eq '+<') { seek $file, 0, 0; }
    elsif ($ope eq '>>') { seek $file, 0, 2; }
    print $file ref $data ? $$data : $data;
    truncate $file, tell($file);
    my $io = IO::Handle->new_from_fd(fileno $file, 'w');
    if ($sync_mode) { $io->sync(); } else { $io->flush(); }
    $io->close();
    close $file;
}

sub _init_date {
    my $date = shift;

    if (defined $date) {
        if (ref $date eq 'Wiz::DateTime') { return $date; }
        else { return new Wiz::DateTime($date); }
    }
    else { return new Wiz::DateTime; }
}

sub parse_csv_file {
    my ($file) = @_;
    my @ret = ();
    open my $f, '<', $file or confess qq|can't open csv file ... $file ($!)|;
    while (<$f>) {
        s/\r?\n$//;
        push @ret, [ split_csv($_) ];
    }
    close $f;
    return wantarray ? @ret : \@ret;
}

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

