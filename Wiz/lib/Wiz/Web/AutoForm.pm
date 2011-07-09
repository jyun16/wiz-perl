package Wiz::Web::AutoForm;

use strict;

=head1 NAME

Wiz::Web::AutoForm

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

SEE L<Wiz::Web::AutoForm::Tutorial>

=cut

use Carp;
use Clone qw(clone);
use Encode qw(decode from_to);
use Encode::Guess;
use Data::Dumper;

use Wiz::Constant qw(:common);
use Wiz::Web qw(html_escape html_unescape);
use Wiz::Web::Constant qw(:escape);
use Wiz::Util::Hash qw(create_ordered_hash args2hash override_hash);
use Wiz::Util::String qw(normal2pascal);
use Wiz::Message;
use Wiz::Validator;
use Wiz::Validator::Constant qw(:error);
use Wiz::Validator::EN;
use Wiz::Validator::JA;
use Wiz::Web::Pager::Basic;
use Wiz::Web::Pager::Google;
use Wiz::Web::Filter;
use Wiz::Web::Sort;
use Wiz::DateTime;

use Wiz::ConstantExporter [qw(
_tag_append_attribute
_tag_append_attributes
_tag_value
_tag_values
_tag_values2hash
__tag_values
)];

use base qw(Class::Accessor::Fast);

no warnings 'uninitialized';

__PACKAGE__->mk_accessors(qw(action conf validator list_values mode));

=head1 CONSTRUCTOR

=cut

my %local_validator = (
    equals          => 1,
    bigger          => 1,
    smaller         => 1,
    max_select      => 1,
    min_select      => 1,
    max_length      => 1,
    min_length      => 1,
    -or             => 1,
);

my %multi_value = (
    checkbox        => 1,
    multiselect     => 1,
    hobby           => 1,
);

my %multi_form = (
    zip_code        => 1,
    phone_number    => 1,
    credit_card_number  => 1,
);

my %need_label_value = (
    select          => 1,
    radio           => 1,
    checkbox        => 1,
    multiselect     => 1,
    gender          => 1,
    prefecture      => 1,
    job             => 1,
    hobby           => 1,
);

sub new {
    my $self = shift;
    my ($action, $param, $conf, $language, $message) = @_;

    my $instance = bless {
        action      => $action,
        list_values => [],
        conf        => $conf,
        language    => $language,
        message     => $message,
        validator   => new Wiz::Validator(type => $language, message => $message),
        mode        => '',
        _opts_map   => undef,
    }, $self;
    $instance->_init_conf;
    if (ref $param eq 'ARRAY') { $instance->list_values($param); }
    else { $instance->params($param); }

    return $instance;
}

=head1 METHODS

=cut

sub conf {
    my $self = shift;
    my ($name) = @_;
    return $self->{conf}{$name};
}

sub _set_by_array {
    my $self = shift;
    my ($name, $label, $options) = @_;
    $options or return;
    my $r = ref $options;
    $self->{conf}{$name}{$label} = $r eq 'HASH' ? [ %$options ] : $options;
}

sub _set_by_hash {
    my $self = shift;
    my ($name, $label, $options) = @_;
    $options or return;
    my $r = ref $options;
    $self->{conf}{$name}{$label} = $r eq 'ARRAY' ? { @$options } : $options;
}

sub append_options {
    my $self = shift;
    my ($name, @options) = @_;
    push @{$self->{conf}{$name}{options}}, @options;
}

sub options {
    my $self = shift;
    my ($name, $options) = @_;
    $self->_set_by_array($name, 'options', $options);
    return $self->{conf}{$name}{options};
}

sub options_as_hash {
    my $self = shift;
    my ($name, $options) = @_;
    $self->_set_by_array($name, 'options', $options);
    return { @{$self->{conf}{$name}{options}} };
}

sub append_validation {
    my $self = shift;
    my ($name, %validation) = @_;
    override_hash $self->{conf}{$name}{validation}, { %validation };
}

sub validation {
    my $self = shift;
    my ($name, $validation) = @_;
    $self->_set_by_hash($name, 'validation', $validation);
    return $self->{conf}{$name}{validation};
}

sub validation_as_hash {
    my $self = shift;
    my ($name, $validation) = @_;
    $self->_set_by_array($name, 'validation', $validation);
    return { @{$self->{conf}{$name}{validation}} };
}

sub append_attribute {
    my $self = shift;
    my ($name, %attribute) = @_;
    override_hash $self->{conf}{$name}{attribute}, { %attribute };
}

sub attribute {
    my $self = shift;
    my ($name, $attribute) = @_;
    ref $attribute and $self->{conf}{$name}{attribute} = $attribute;
    return $self->{conf}{$name}{validation};
}

sub attribute_as_hash {
    my $self = shift;
    my ($name, $attribute) = @_;
    ref $attribute and $self->{conf}{$name}{attribute} = $attribute;
    return { @{$self->{conf}{$name}{attribute}} };
}

sub complement_params {
    my $self = shift;
    my ($params) = @_;

    my $conf = $self->{conf};
    for my $name (keys %$conf) {
        my $c = $conf->{$name};
        ref $c ne 'HASH' and next;
        my $t = $c->{type};
        if ($t eq 'datetime' or $multi_value{$t} or $multi_form{$t}) {
            $params->{$name} = $self->value($name);
        }
    }
    return $params;
}

sub clear_password_value {
    my $self = shift;

    my $conf = $self->{conf};
    for my $name (keys %$conf) {
        my $c = $conf->{$name};
        ref $c ne 'HASH' and next;
        if ($c->{type} eq 'password') {
            $self->param($name => '');
        }
    }
}

sub check_params {
    my $self = shift;
    $self->{validator}->clear;
    $self->continue_check_params;
}

sub continue_check_params {
    my $self = shift;

    my $conf = $self->{conf};
    my $p = $self->{param};

    for my $name (keys %$conf) {
        my $c = $conf->{$name};
        ref $c ne 'HASH' and next;
        my $t = $c->{type};
        if ($c->{split_value_on_validation} and $p->{$name} ne '') {
            my $w = '\s';
            if (ref $c->{split_value_on_validation}) {
                $w = $c->{split_value_on_validation}{split};
            }
            for (split /$w/, $p->{$name}) {
                $self->_check_param($name, $_, $c);
            }
        }
        else {
            $self->_check_param($name, $self->value($name), $c);
        }
    }
}

sub _check_param {
    my $self = shift;
    my ($name, $value, $conf) = @_;

    my $validation = $conf->{validation};
    for my $v (keys %$validation) {
        $validation->{$v} or next;
        $self->{validator}->can($v) and
            $self->{validator}->$v($name => $value);
    }
    $validation = $conf->{_validation};
    for my $v (keys %$validation) {
        if ($v eq '-or') {
            my $confs = $validation->{'-or'};
            for (my $i = 0; $i < @$confs; $i+=2) {
                $confs->[$i+1] or next;
                my $m = $confs->[$i];
                if ($self->{validator}->$m($name => $value)) {
                    $self->{validator}->remove_error($name);
                    last;
                }
            }
        }
        else {
            defined $validation->{$v} or next;
            my $m = "_validation_${v}";
            $self->$m($name, $value, $conf, $conf->{_validation}{$v});
        }
    }
}

sub param {
    my $self = shift;
    my ($name, $value) = @_;

    if (@_ > 1) {
        $self->{param}{$name} = $self->_param_value($name, $value, $self->{conf}{$name});
    }
    return $self->{param}{$name};
}

sub params {
    my $self = shift;
    if (@_) {
        my $param = clone args2hash(@_);
        my $conf = $self->{conf};
        for (keys %$param) {
            $param->{$_} = $self->_param_value($_, $param->{$_}, $conf->{$_});
        }
        $self->{param} = $param;
    }
    return $self->{param};
}

sub language {
    my $self = shift;
    my ($language) = @_;

    if (defined $language) {
        $self->{language} = $language;
        $self->{validator}->type($language);
        defined $self->{message} and $self->{message}->language($language);
        return;
    }
    return $self->{language};
}

sub output_encode {
    my $self = shift;
    my ($data) = @_;

    if (exists $self->{conf}{_output_encoding}) {
        my $out = $self->{conf}{_output_encoding};
        ref $data or $data = \$data;
        my $in = $self->{_input_encoding};
        if ($in eq '') { $in = guess_encoding($$data)->name; $in eq 'utf8' and $in = 'utf-8'; }
        if ($in ne lc $out) {
            return from_to($$data, $in, $out);
        }
    }

    return 0;
}

sub message {
    my $self = shift;
    my ($message) = @_;

    if (defined $message) {
        $self->{validator} =
            new Wiz::Validator(type => $self->{language}, message => $message);
        $self->{message} = $message;
        return;
    }
    return $self->{validator};
}

sub tag {
    my $self = shift;
    my ($name, $value, $option) = @_;

    $self->check_exists_conf($name);
    my $p = $self->{param};
    my $c = $self->{conf}{$name};
    my $t = $c->{type};
    my $m = "_tag_$c->{type}";
    $self->can($m) or die "[AutoForm::tag] bad form type($name: $c->{type})";
    my $tag = undef;
    if ($t eq 'datetime') { $tag = $self->$m($name, $self->_datetime_params2value($name), $c); }
    else {
        my $v = defined $value ? $value : defined $p->{$name} ? $p->{$name} : $self->value($name);
        $tag = $self->$m($name, $v, $c, $option);
    }

    $self->output_encode(\$tag);
    return $tag;
}

sub form_type {
    my $self = shift;
    my ($name) = @_;
    return $self->{conf}{$name}{type} || '';
} 

sub value {
    my $self = shift;
    my ($name, $delimiter) = @_;
    
    my $c = $self->{conf}{$name};
    my $t = $c->{type};
    my $p = $self->{param};
    my $ret = undef;
    if ($c->{joined_value}) {
        if ($multi_form{$t}) {
            $p->{$name} and do { $ret = $p->{$name}; goto RET; }
        }
        defined $delimiter or $delimiter = defined $c->{delimiter} ? $c->{delimiter} : '';
        my @ret = ();
        for (@{$c->{joined_value}}) {
            $p->{$_} eq '' and do { $ret = ''; goto RET; };
            push @ret, $p->{$_};
        }
        $ret = join $delimiter, @ret;
    }
    elsif ($t eq 'datetime') { $ret = $self->_datetime_params2value($name); }
    else { $ret = $p->{$name}; }
RET:
    defined $ret or $ret = $c->{default};
    return $ret;
};

sub check_exists_conf {
    my $self = shift;
    my ($name) = @_;
    exists $self->{conf}{$name} or 
        die "[AutoForm] not exists config for $name";
}

sub item_label {
    my $self = shift;
    my ($name) = @_;

    $self->check_exists_conf($name);

    my $ret = undef;
    if (defined $self->{message}) {
        $ret = $self->{message}->get('item_label', $self->{action}, $name);
    }
    $ret ||= $self->{conf}{$name}{item_label};
    return $ret;
}

sub sort_item {
    my $self = shift;
    my ($name) = @_;
    return ($name, $self->item_label($name));
}

sub label {
    my $self = shift;
    my ($name, $value) = @_;

    $self->check_exists_conf($name);

    my $c = $self->{conf}{$name};
    my $t = $c->{type};
    my $ret = undef;
    my $m = "_label_$t";
    $self->can($m) or die "[AutoForm::label] bad form type($name: $t)";
    $ret = $self->$m($name, $value, $c);
    $self->output_encode(\$ret);
    return $ret;
}

sub value_label {
    my $self = shift;
    my ($name, $delimiter) = @_;
    return $self->label($name, $self->value($name, $delimiter));
}

sub filterd_value {
    my $self = shift;
    my ($name, $value) = @_;

    no strict 'refs';
    $value = $self->value($name, $value) if not defined $value;
    my $c = $self->{conf}{$name};
    my $filters = $c->{filter}; 
    if ($filters) { 
        $filters = args2hash($filters);
        for (keys %$filters) {
            "Wiz::Web::Filter::$_"->(\$value, $filters->{$_});
        }
    }
    return $value;
}

sub html_value {
    my $self = shift;
    my ($name, $value) = @_;

    no strict 'refs';
    my $c = $self->{conf}{$name};
    my $t = $c->{type};
    $value = $self->value($name, $value) if not defined $value;
    $need_label_value{$t} and $value = $self->label($name, $value);
    html_escape(\$value);
    my $filters = $c->{filter}; 
    if ($filters) { 
        $filters = args2hash($filters);
        for (keys %$filters) {
            "Wiz::Web::Filter::$_"->(\$value, $filters->{$_});
        }
    }
    return ref $value ? '' : $value;
}

sub tagmap {
    my $self = shift;
    my ($name) = @_;

    $self->check_exists_conf($name);

    my $c = $self->{conf}{$name};
    my $m = "_tag_$c->{type}";
    $self->can($m) or die "[AutoForm::tagmap] bad form type($name: $c->{type})";
    my $tags = $self->$m($name, $self->{param}{$name}, $c);
    my $opts = [ values %{$self->_opts_map($name, $c)} ];

    my $ret = create_ordered_hash;
    my $cnt = 0;
    for (@$tags) {
        $ret->{$_} = $opts->[$cnt];
        ++$cnt;
    }

    return $ret;
}

sub has_error {
    my $self = shift;
    $self->{validator}->has_error(@_);
}

sub error {
    my $self = shift;
    $self->{validator}->error(@_);
}

sub error_label {
    my $self = shift;
    $self->{validator}->error_label(@_);
}

sub error_message {
    my $self = shift;
    $self->{validator}->error_message(@_);
}

sub outer_error {
    my $self = shift;
    $self->{validator}->outer_error(@_);
}

sub outer_error_label {
    my $self = shift;
    $self->{validator}->outer_error_label(@_);
}

sub outer_error_message {
    my $self = shift;
    $self->{validator}->outer_error_message(@_);
}

sub errors {
    shift->{validator}->errors;
}

sub errors_labels {
    my $self = shift;
    $self->{validator}->errors_labels(@_);
}

sub errors_messages {
    my $self = shift;
    $self->{validator}->errors_messages(@_);
}

sub remove_errors {
    my $self = shift;
    $self->{validator}->remove_errors(@_);
}

sub clear {
    my $self = shift;

    $self->{param} = {};
    $self->{validator}->clear;
    $self->{list_values} = [];

    $self->{_tags} = undef;
    $self->{_opts_map} = undef;
    $self->{cache} = {};
}

sub forms  {
    my $self = shift;
    return $self->{conf}{_forms};
}

sub input_forms  {
    my $self = shift;
    return $self->{conf}{_input_forms};
}

sub input_form_status  {
    my $self = shift;
    return $self->{conf}{_input_form_status};
}

sub confirm_forms  {
    my $self = shift;
    return $self->{conf}{_confirm_forms} ? 
        $self->{conf}{_confirm_forms} :
        $self->{conf}{_input_forms};
}

sub search_forms  {
    my $self = shift;
    return $self->{conf}{_search_forms};
}

sub list_forms  {
    my $self = shift;
    return $self->{conf}{_list_forms};
}

sub show_forms  {
    my $self = shift;
    return $self->{conf}{_show_forms};
}

sub skip_not_empty  {
    my $self = shift;
    return $self->{conf}{_skip_not_empty};
}

sub pager {
    my $self = shift;
    my ($name) = @_;
    $name ||= '';
    $self->{cache}{pager} ||= {}; 
    my $cache = $self->{cache}{pager};
    unless (defined $cache->{$name}) {
        if (ref $self->{conf}{_pager}) {
            my $type = $self->{conf}{_pager}{type} || 'basic';
            my $pkg = "Wiz::Web::Pager::" . normal2pascal($type);
            $cache->{$name} = $pkg->new($self->{conf}{_pager});
        }
        else {
            my $type = $self->{conf}{_pager} || 'basic';
            my $pkg = "Wiz::Web::Pager::" . normal2pascal($type);
            $cache->{$name} = $pkg->new;
        }
    }
    return $cache->{$name};
}

sub sort {
    my $self = shift;
    my ($name) = @_;
    $name ||= '';
    $self->{cache}{sort} ||= {};
    my $cache = $self->{cache}{sort};
    unless (defined $cache->{$name}) {
        $cache->{$name} = new Wiz::Web::Sort($self->{conf}{_sort} || {});
    }
    return $cache->{$name};
}

sub calendar {
    my $self = shift;
    my ($name) = @_;

    $name ||= '';
    $self->{cache}{calendar} ||= {};

    my $cache = $self->{cache}{calendar};
    unless (defined $cache->{$name}) {
        my $conf = $self->{conf}{_calendar};
        my ($pkg, $instance);
        if (ref $conf eq 'HASH') {
            $conf->{calendars} and $conf = $conf->{calendars}{$name};
            $pkg = "Wiz::Web::Calendar::" . normal2pascal($conf->{type});
            $instance = $pkg->new($conf);
        }
        else {
            $pkg = "Wiz::Web::Calendar::" . normal2pascal($conf);
            $instance = $pkg->new;
        }
        $cache->{$name} = $instance;
    }
    return $cache->{$name};
}

sub is_multi_value {
    my $self = shift;
    my ($name) = @_;
    return $multi_value{$self->form_type($name)} || FALSE;
}

sub is_join_mode {
    my $self = shift;
    my ($name) = @_;
    return $self->{$name}{join} || FALSE;
}

# ----[ private ]-----------------------------------------------------
sub _param_value {
    my $self = shift;
    my ($name, $value, $conf) = @_;
    my $t = $conf->{type};
    if ($multi_value{$t}) {
        unless (ref $value) {
            $value !~ /^\t/ and $value .= "\t$value";
            $value = [ split /\t/, $value ];
            shift @$value;
        }
    }
    elsif ($t eq 'date' or $t eq 'time' or $t eq 'datetime') {
        $self->_datetime_value2params($name, $value);
    }
    else {
        no strict 'refs';
        if ($conf->{input_filter}) {
            my $filters = $conf->{input_filter}; 
            if ($filters) { 
                for (keys %$filters) {
                    "Wiz::Web::Filter::$_"->(\$value, $filters->{$_});
                }
            }
        }
    }
    return $value;
}

sub _append_attribute_tag_conf {
    my $self = shift;
    my ($conf, $option) = @_;
    (!$option and !$option->{attribute}) and return $conf;
    my $ret = clone $conf;
    override_hash $ret->{attribute}, $option->{attribute};
    return $ret;
}

sub _tag_text {
    my $self = shift;
    my ($name, $value, $conf, $option) = @_;
    $value = _tag_value($value, $conf);
    my $tag = qq|<input type="text" name="$name" value="$value"|;
    $conf = $self->_append_attribute_tag_conf($conf, $option);
    $tag .= _tag_append_attribute($conf->{attribute});
    $tag .= '>';
    return $tag;
}

sub _tag_password {
    my $self = shift;
    my ($name, $value, $conf, $option) = @_;
    $value = _tag_value($value, $conf);
    my $tag = qq|<input type="password" name="$name" value="$value"|;
    $conf = $self->_append_attribute_tag_conf($conf, $option);
    $tag .= _tag_append_attribute($conf->{attribute});
    $tag .= '>';
    return $tag;
}

sub _tag_textarea {
    my $self = shift;
    my ($name, $value, $conf, $option) = @_;
    $value = _tag_value($value, $conf);
    my $tag = qq|<textarea name="$name"|;
    $conf = $self->_append_attribute_tag_conf($conf, $option);
    $tag .= _tag_append_attribute($conf->{attribute});
    $tag .= qq|>$value</textarea>|;
    return $tag;
}

sub _tag_select {
    my $self = shift;
    my ($name, $value, $conf, $option) = @_;
    $value = _tag_value($value, $conf);
    my $o = $conf->{options};
    if ($option and $option->{options}) { $o = $option->{options}; }
    $o or return;
    my $tag = qq|<select name="$name"|;
    $conf = $self->_append_attribute_tag_conf($conf, $option);
    $tag .= _tag_append_attribute($conf->{attribute});
    $tag .= '>';
    my %exclude_options = ();
    if (defined $option->{exclude_options}) {
        if (ref $option->{exclude_options}) {
            for (@{$option->{exclude_options}}) { $exclude_options{$_} = 1; }
        }
        else { $exclude_options{$option->{exclude_options}} = 1; }
    }
    for (my $i = 0; $i < @$o; $i+=2) {
        $exclude_options{$o->[$i]} and next;
        my $v = html_escape $o->[$i];
        my $l = html_escape $o->[$i+1];
        $tag .= qq|<option value="$v"|;
        $v eq $value and $tag .= ' selected';
        $tag .= qq|>$l|;
    }
    $tag .= '</select>';

    return $tag;
}

sub _tag_multiselect {
    my $self = shift;
    my ($name, $values, $conf, $option) = @_;
    $values = _tag_values2hash($values, $conf);
    my $tag = qq|<select name="$name" multiple|;
    $conf = $self->_append_attribute_tag_conf($conf, $option);
    $tag .= _tag_append_attribute($conf->{attribute});
    $tag .= '>';
    my $o = $conf->{options};
    for (my $i = 0; $i < @$o; $i+=2) {
        my $v = html_escape $o->[$i];
        my $l = html_escape $o->[$i+1];
        $tag .= qq|<option value="$v"|;
        $values->{$v} and $tag .= ' selected';
        $tag .= qq|>$l|;
    }
    $tag .= '</select>';

    return $tag;
}

sub _tag_radio {
    my $self = shift;
    my ($name, $value, $conf, $option) = @_;
    $value = _tag_value($value, $conf);
    my @tags = ();
    my $o = $conf->{options};
    $conf = $self->_append_attribute_tag_conf($conf, $option);
    my $attr = ref $conf->{attribute} eq 'HASH' ?
        _tag_append_attribute($conf->{attribute}) : undef;
    for (my $i = 0; $i < @$o; $i+=2) {
        my $v = html_escape $o->[$i];
        my $tag = qq|<input type="radio" name="${name}" value="$v"|;
        $tag .= defined $attr ? $attr : _tag_append_attributes($conf->{attribute}, $i / 2);
        $v eq $value and $tag .= ' checked';
        $tag .= '>';
        $conf->{split} or $tag .= html_escape $o->[$i+1];
        push @tags, $tag;
    }
    return \@tags;
}

sub _tag_checkbox {
    my $self = shift;
    my ($name, $values, $conf, $option) = @_;
    $values = _tag_values2hash($values, $conf);
    my @tags = ();
    my $o = $conf->{options};
    $conf = $self->_append_attribute_tag_conf($conf, $option);
    my $attr = ref $conf->{attribute} eq 'HASH' ?
        _tag_append_attribute($conf->{attribute}) : undef;
    for (my $i = 0; $i < @$o; $i+=2) {
        my $v = html_escape $o->[$i];
        my $tag = qq|<input type="checkbox" name="${name}" value="$v"|;
        $tag .= defined $attr ? $attr : _tag_append_attributes($conf->{attribute}, $i / 2);
        defined $values->{$v} and $tag .= ' checked';
        $tag .= '>';
        defined $conf->{separator} and $tag .= $conf->{separator};
        $conf->{split} or $tag .= html_escape $o->[$i+1];
        defined $conf->{join} and $tag .= $conf->{join};
        push @tags, $tag;
    }
    return \@tags;
}

sub _tag_select_with_options {
    my $self = shift;
    my ($name, $value, $conf, $options) = @_;
    unless ($conf->{options}) {
        if (defined $conf->{empty}) {
            my @options = @$options;
            if ($options[1] eq '') {
                $options[1] = $conf->{empty};
            }
            $conf->{options} = \@options;
        }
        else {
            $conf->{options} = $options;
        }
    }
    return $self->_tag_select($name, $value, $conf);
}

sub _tag_checkbox_with_options {
    my $self = shift;
    my ($name, $value, $conf, $options) = @_;
    $conf->{options} ||= $options;
    return $self->_tag_checkbox($name, $value, $conf);
}

sub _tag_file {
    my $self = shift;
    my ($name, $value, $conf) = @_;

    $value = _tag_value($value, $conf);
    my $tag = qq|<input type="file" name="$name" value="$value"|;
    $tag .= _tag_append_attribute($conf->{attribute});
    $tag .= '>';
}

sub _tag_email {
    my $self = shift;
    my ($name, $value, $conf) = @_;

    $conf->{attribute}{size} ||= 60;
    $conf->{attribute}{maxlength} ||= 255;

    $value = _tag_value($value, $conf);
    my $tag = qq|<input type="text" name="$name" value="$value"|;
    $tag .= _tag_append_attribute($conf->{attribute});
    $tag .= '>';
}

sub _tag_credit_card_number {
    my $self = shift;
    my ($name, $value, $conf) = @_;
    my @value = split /-/, $value;
    $conf->{attribute}{size} = 4; $conf->{attribute}{maxlength} = 4;
    my $ret = $self->_tag_text("${name}_1", $value[0], $conf) . '-';
    $ret .= $self->_tag_text("${name}_2", $value[1], $conf) . '-';
    $ret .= $self->_tag_text("${name}_3", $value[2], $conf) . '-';
    $ret .= $self->_tag_text("${name}_4", $value[3], $conf);
}

sub _tag_date {
    my $self = shift;
    my ($name, $value, $conf) = @_;

    my $attr = ref $conf->{attribute} eq 'HASH' ?
        _tag_append_attribute($conf->{attribute}) : undef;
    my $d = new Wiz::DateTime;
    my $now_y = $d->year;
    my ($sy, $ey) = ($conf->{start_year} || $now_y, $conf->{end_year} || $now_y);
    $sy eq 'now' and $sy = $now_y;
    $ey eq 'now' and $ey = $now_y;
    my $dt = undef;
    my ($year, $month, $day);
    $value ||= $self->{param}{$name};
    if ($value) { ($year, $month, $day) = split /-/, $value; }
    elsif ($conf->{default} ne '') {
        $dt = $conf->{default} eq 'now' ?
            new Wiz::DateTime : new Wiz::DateTime($conf->{default});
        ($year, $month, $day) = split /-/, $dt->ymd if defined $dt;
    }
    if ($conf->{text_mode}) {
        my $vd = new Wiz::DateTime("$year-$month-$day");
        if ($vd) {
            $vd->set_format($conf->{input_format} || '%Y-%m-%d');
        }
        my $tag = qq|<input type="text" name="$name" value="| . ($vd and $vd->to_string) . q|"|;
        $tag .= _tag_append_attribute($conf->{attribute});
        $tag .= '>';
        return $tag;
    }
    else {
        my ($attr_y, $attr_m, $attr_d) = $attr ? ($attr, $attr, $attr) :
            (
                _tag_append_attributes($conf->{attribute}, 0),
                _tag_append_attributes($conf->{attribute}, 1),
                _tag_append_attributes($conf->{attribute}, 2),
            );
        return {
            year    => $conf->{year_order} eq 'asc' ? 
                __tag_datetime_select(
                    "${name}_y", $sy, $ey, $attr_y, $year, '%04d', $conf->{empty}) :
                __tag_datetime_select(
                    "${name}_y", $ey, $sy, $attr_y, $year, '%04d', $conf->{empty}),
            month   => __tag_datetime_select(
                "${name}_m", '01', '12', $attr_m, $month, '%02d', $conf->{empty}),
            day     => __tag_datetime_select(
                "${name}_d", '01', '31', $attr_d, $day, '%02d', $conf->{empty}),
        };
    }
}

sub _tag_time {
    my $self = shift;
    my ($name, $value, $conf) = @_;

    my $attr = ref $conf->{attribute} eq 'HASH' ?
        _tag_append_attribute($conf->{attribute}) : undef;
    my $dt = undef;
    $value ||= $self->{param}{$name};

    if ($value) { $dt = new Wiz::DateTime('1970/01/01 ' . $value); }
    elsif ($conf->{default} ne '') {
        $dt = $conf->{default} eq 'now' ?
            new Wiz::DateTime : new Wiz::DateTime('1970/01/01 ' . $conf->{default});
    }
    my ($hour, $min, $sec) = split /:/, $dt->hms if defined $dt;
    my $o = $conf->{time_only} ? 0 : 3;
    my ($attr_h, $attr_m, $attr_s) = $attr ? ($attr, $attr, $attr) :
        (
            _tag_append_attributes($conf->{attribute}, $o),
            _tag_append_attributes($conf->{attribute}, $o + 1),
            _tag_append_attributes($conf->{attribute}, $o + 2),
        );
    return {
        hour    => __tag_datetime_select(
            "${name}_h", '00', '23', $attr_h, $hour, '%02d', $conf->{empty}),
        minute  => __tag_datetime_select(
            "${name}_mi", '00', '59', $attr_m, $min, '%02d', $conf->{empty}),
        second  => __tag_datetime_select(
            "${name}_s", '00', '59', $attr_s, $sec, '%02d', $conf->{empty}),
    };
}

sub _tag_datetime {
    my $self = shift;
    my ($name, $value, $conf) = @_;
    my ($dv, $tv) = split / /, $value;
    $tv ||= $dv;
    my $d = $conf->{time_only} ? {} : $self->_tag_date($name, $dv, $conf);
    my $t = $conf->{date_only} ? {} : $self->_tag_time($name, $tv, $conf);
    if (ref $d) { @$d{keys %$t} = values %$t; }
    return $d;
}

sub __tag_datetime_select {
    my ($name, $start, $end, $attr, $selected, $fmt, $empty) = @_;

    my $tag = qq|<select name="$name"$attr>|;
    if (defined $empty) {
        my ($l1, $l2) = (length $start, length $end);
        my $l = $l1 > $l2 ? $l1 : $l2;
        $tag .= qq|<option value=""|;
        $selected eq '' and $tag .= ' selected';
        $tag .= '>' . $empty x $l;
    }
    my @list = $start > $end ? reverse ($end..$start) : ($start..$end);
    for (@list) {
        my $v = defined $fmt ? sprintf $fmt, $_ : $_; 
        $tag .= qq|<option value="$v"|;
        if ($selected eq '') { $_ eq $selected and $tag .= ' selected'; }
        else { $_ == $selected and $tag .= ' selected'; }
        $tag .= qq|>$v|;
    }
    $tag .= '</select>';
    return $tag;
}

sub _opts_map {
    my $self = shift;
    my ($name, $conf) = @_;

    defined $conf->{options} or return undef;
    defined $self->{_opts_map}{$name} and 
        return $self->{_opts_map}{$name};
    my $opts = $conf->{options};
    my $ret = create_ordered_hash;
    for (my $i = 0; $i < @$opts; $i+=2) {
        $ret->{$opts->[$i]} = $opts->[$i+1];
    }
    $self->{_opts_map}{$name} = $ret;
    return $ret;
}

sub _label_select {
    my $self = shift;
    return $self->_label_single(@_);
}

sub _label_multiselect {
    my $self = shift;
    $self->_label_multi(@_);
}

sub _label_radio {
    my $self = shift;
    return $self->_label_single(@_);
}

sub _label_checkbox {
    my $self = shift;
    $self->_label_multi(@_);
}

sub _label_date {
    my $self = shift;
    my ($name, $value, $conf) = @_;

    my $p = $self->{param};
    my $dt = $value ne '' ? 
        new Wiz::DateTime($value) : 
        do {
            my $dv = $self->_date_params2value($name);
            $dv ? new Wiz::DateTime($dv) : return '';
        };
    if ($conf->{format}) {
        $dt->set_format($conf->{format});
        return $dt->to_string;
    }
    else { return $dt->ymd; }
}

sub _label_time {
    my $self = shift;
    my ($name, $value, $conf) = @_;

    my $p = $self->{param};
    my $dt = $value ne '' ? 
        new Wiz::DateTime('1970-01-01 ' . $value) : 
        do {
            my $dv = $self->_time_params2value($name);
            $dv ? new Wiz::DateTime('1970-01-01 ' . $dv) : return '';
        };
    if ($conf->{format}) {
        $dt->set_format($conf->{format});
        return $dt->to_string;
    }
    else { return $dt->hms; }
}

sub _label_datetime {
    my $self = shift;
    my ($name, $value, $conf) = @_;

    if ($conf->{time_only}) {
        return $self->_label_time(@_);
    }
    elsif ($conf->{date_only}) {
        return $self->_label_date(@_);
    }
    my $p = $self->{param};
    my $dt = $value ne '' ? 
        new Wiz::DateTime($value) : 
        do {
            my $dv = $self->_datetime_params2value($name);
            $dv ? new Wiz::DateTime($dv) : return '';
        };
    defined $conf->{format} and $dt->set_format($conf->{format});
    return $dt->to_string;
}

sub _label_single {
    my $self = shift;
    my ($name, $value, $conf) = @_;
    my $opts = $self->_opts_map($name, $conf);
    defined $opts or return '';
    return defined $value ? html_escape($opts->{$value}) : [ values %$opts ];
}

sub _label_multi {
    my $self = shift;
    my ($name, $values, $conf) = @_;

    my $opts = $self->_opts_map($name, $conf);
    defined $opts or return [];
    return defined $values ? do {
        ref $values or $values = [ $values ];
        [ map { $opts->{$_} } @$values ];
    } : [ values %$opts ];
}

sub _label_select_with_options {
    my $self = shift;
    my ($name, $value, $conf, $options) = @_;

    unless ($conf->{options}) {
        $conf->{options} = defined $conf->{empty} ?
            [ ((0, $conf->{empty}), @$options) ] : $options;
    }
    return $self->_label_select($name, $value, $conf);
}

sub _label_checkbox_with_options {
    my $self = shift;
    my ($name, $value, $conf, $options) = @_;

    unless ($conf->{options}) {
        $conf->{options} = defined $conf->{empty} ?
            [ ((0, $conf->{empty}), @$options) ] : $options;
    }
    return $self->_label_checkbox($name, $value, $conf);
}

sub _date_params2value {
    my $self = shift;
    my ($name) = @_;
    my $p = $self->{param};

    if ($p->{$name}) {
        my $d = new Wiz::DateTime($p->{$name});
        if ($d) { return $d->ymd; }
        else {
            $self->_date_value2params($name, $p->{$name});
            return $p->{$name};
        }
    }
    if ($p->{"${name}_y"} ne '' and $p->{"${name}_m"} ne '' and $p->{"${name}_d"} ne '') {
        return sprintf '%s-%s-%s', $p->{"${name}_y"}, $p->{"${name}_m"}, $p->{"${name}_d"};
    }
    else { return ''; }
}

sub _time_params2value {
    my $self = shift;
    my ($name) = @_;
    my $p = $self->{param};

    if ($p->{$name}) { my $d = new Wiz::DateTime($p->{$name}); $d ? $d->hms : undef; }
    elsif ($p->{"${name}_h"} ne '' and $p->{"${name}_mi"} ne '' and $p->{"${name}_s"} ne '') {
        return sprintf '%s:%s:%s', $p->{"${name}_h"}, $p->{"${name}_mi"}, $p->{"${name}_s"};
    }
    else { return ''; }
}

sub _datetime_params2value {
    my $self = shift;
    my ($name) = @_;
    my $c = $self->{conf}{$name};
    if ($c->{date_only}) {
        return $self->_date_params2value($name);
    }
    elsif ($c->{time_only}) {
        return $self->_time_params2value($name);
    }
    else {
        my $d = $self->_date_params2value($name);
        my $t = $self->_time_params2value($name);
        return ($d ne '' and $t ne '') ? "$d $t" : '';
    }
}

sub _date_value2params {
    my $self = shift;
    my ($name, $value) = @_;
    my $p = $self->{param};
    my @d = split /-/, $value;
    $p->{"${name}_y"} = $d[0];
    $p->{"${name}_m"} = $d[1];
    $p->{"${name}_d"} = $d[2];
}

sub _time_value2params {
    my $self = shift;
    my ($name, $value) = @_;
    my $p = $self->{param};
    my @t = split /:/, $value;
    $p->{"${name}_h"} = $t[0];
    $p->{"${name}_mi"} = $t[1];
    $p->{"${name}_s"} = $t[2];
}

sub _datetime_value2params {
    my $self = shift;
    my ($name, $value) = @_;

    my $c = $self->{conf}{$name};
    if ($c->{date_only}) { $self->_date_value2params($name, $value); }
    elsif ($c->{time_only}) { $self->_time_value2params($name, $value); }
    else {
        my ($d, $t) = split / /, $value;
        $self->_date_value2params($name, $d);
        $self->_time_value2params($name, $t);
    }
}

sub _init_conf {
    my $self = shift;

    my $conf = $self->{conf};
    for my $k (keys %$conf) {
        my $c = $conf->{$k};
        my @del = ();
        ref $c ne 'HASH' and next;
        for my $v (%{$c->{validation}}) {
            if (exists $local_validator{$v}) {
                $c->{_validation}{$v} = $c->{validation}{$v};
                push @del, $v;
            }
        }
        for (@del) { delete $c->{validation}{$_}; }
        if (defined $c->{type}) {
            if ($c->{type} eq 'email') { $c->{validation}{is_email_address} = 1; }
            elsif ($c->{type} eq 'datetime') {
                $c->{validation}{is_valid_date} = 1;
            }
            elsif ($c->{type} eq 'credit_card_number') {
                $c->{joined_value} = [ "${k}_1", "${k}_2", "${k}_3", "${k}_4" ];
                $c->{delimiter} = '-'; $c->{validation}{is_credit_card_number} = 1;
            }
            elsif ($c->{type} eq 'zip_code') {
                $c->{joined_value} = [ "${k}_1", "${k}_2" ];
                $c->{delimiter} = '-'; $c->{validation}{is_zip_code} = 1;
            }
            elsif ($c->{type} eq 'phone_number') {
                $c->{joined_value} = [ "${k}_1", "${k}_2", "${k}_3" ];
                $c->{delimiter} = '-'; $c->{validation}{is_phone_number} = 1;
            }
        }
    }
}

sub _validation_max_select {
    my $self = shift;
    my ($name, $value, $conf, $vconf) = @_;

    ref $value ne 'ARRAY' and $value = [ $value ];
    if (@$value > $vconf) {
        $self->{validator}{errors}{$name} = OVER_MAX_SELECT;
    }
}

sub _validation_min_select {
    my $self = shift;
    my ($name, $value, $conf, $vconf) = @_;

    ref $value ne 'ARRAY' and $value = [ $value ];
    if (@$value < $vconf) {
        $self->{validator}{errors}{$name} = SHORT_MIN_SELECT;
    }
}

sub _validation_equals {
    my $self = shift;
    my ($name, $value, $conf, $vconf) = @_;

    if ($self->{param}{$name} ne $self->{param}{$vconf}) {
        $self->{validator}{errors}{$name} = NOT_EQUALS;
    }
}

sub __validation_compare {
    my $self = shift;
    my ($name, $value, $conf, $vconf) = @_;

    my $p = $self->{param};
    my $t = $conf->{type};
    if ($t eq 'datetime') {
        $value eq '' and return;

        my $dt1 = new Wiz::DateTime($value);
        my $dt2 = undef;
        my $dtv2 = $self->value($vconf);
        if ($dtv2 ne '') {
            return ($dt1, new Wiz::DateTime($dtv2));
        }
    }
    else {
        if ($vconf =~ /^\d*$/) { return ($value, $vconf); }
        else { return ($value, $p->{$vconf}); }
    }
}

sub _validation_max_length {
    my $self = shift;
    my ($name, $value, $conf, $vconf) = @_;
    $value eq '' and return;
    my $in = $self->{_input_encoding};
    if ($in eq '') { $in = guess_encoding($value)->name; $in eq 'utf8' and $in = 'utf-8'; }
    $value = decode($in, $value);
    if (length $value > $vconf) {
        $self->{validator}{errors}{$name} = OVER_MAX_LENGTH;
    }
}

sub _validation_min_length {
    my $self = shift;
    my ($name, $value, $conf, $vconf) = @_;
    $value eq '' and return;
    my $in = $self->{_input_encoding};
    if ($in eq '') { $in = guess_encoding($value)->name; $in eq 'utf8' and $in = 'utf-8'; }
    $value = decode($in, $value);
    if (length $value < $vconf) {
        $self->{validator}{errors}{$name} = SHORT_MIN_LENGTH;
    }
}

sub _validation_bigger {
    my $self = shift;
    my ($name, $value, $conf, $vconf) = @_;
    $value eq '' and return;
    my ($t1, $t2) = $self->__validation_compare($name, $value, $conf, $vconf);
    if ($t1 < $t2) {
        $self->{validator}{errors}{$name} = NOT_BIGGER;
    }
}

sub _validation_smaller {
    my $self = shift;
    my ($name, $value, $conf, $vconf) = @_;
    $value eq '' and return;
    my ($t1, $t2) = $self->__validation_compare($name, $value, $conf, $vconf);
    $t2 or return;
    if ($t1 > $t2) {
        $self->{validator}{errors}{$name} = NOT_SMALLER;
    }
}

=head1 FUNCTIONS

=cut

# ----[ static ]------------------------------------------------------
# ----[ private static ]----------------------------------------------
sub _tag_append_attribute {
    my ($attr, $escape) = @_;

    defined $attr or return '';
    defined $escape or $escape = HTML_ESCAPE;
    %$attr or return '';
    my $tag = '';
    for (keys %$attr) {
        if ($_ ne 'value') {
            defined $attr->{$_} or next;
            my $a = ($escape == NON_ESCAPE) ? $attr->{$_} : html_escape($attr->{$_});
            $tag .= qq| $_="$a"|;
        }
    }
    return $tag;
}

sub _tag_append_attributes {
    my ($attrs, $i, $escape) = @_;

    defined $attrs or return '';
    defined $escape or $escape = HTML_ESCAPE;
    ref $attrs eq 'HASH' and return _tag_append_attribute($attrs, $escape);
    return _tag_append_attribute($attrs->[$i], $escape);
}

sub _tag_value {
    my ($value, $conf, $escape) = @_;

    defined $escape or $escape = HTML_ESCAPE;
    if (not defined $value) {
        $value = $conf->{default} ne '' ? $conf->{default} : '';
    }
    return ($escape == NON_ESCAPE) ? $value : html_escape($value);
}

sub _tag_values {
    return __tag_values(@_);
}

sub __tag_values {
    my ($values, $conf, $escape) = @_;

    defined $escape or $escape = HTML_ESCAPE;
    if (not defined $values or @$values == 0) {
        $values = defined $conf->{default} ?
            (ref $conf->{default} ? $conf->{default} : [ $conf->{default} ]) : [];
    }
    for (@$values) { $_ = ($escape == NON_ESCAPE) ? $_ : html_escape($_); }
    return $values;
}

sub _tag_values2hash {
    my ($values, $conf, $escape) = @_;

    defined $values and ref $values ne 'ARRAY' and $values = [ $values ];
    defined $escape or $escape = HTML_ESCAPE;
    $values = __tag_values($values, $conf, $escape); 
    if ($escape == NON_ESCAPE) { return { map { $_ => 1 } @$values }; }
    else { return { map { html_escape($_) => 1 } @$values }; }
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

If the value of date(yyyy-mm-dd) is included in the instance, the value is be preference.

