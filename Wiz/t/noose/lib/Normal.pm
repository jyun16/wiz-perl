package Normal;

use Wiz::Noose;

use Wiz::Dumper;

has 'member' => (is => 'rw');
has 'member_ro' => (is => 'ro');
has 'member_default' => (is => 'rw', default => 'DEFAULT');
has 'required_member' => (is => 'rw', required => 1);
has 'setter_test' => (is => 'rw', setter => sub {
    my $self = shift;    
    my ($args) = @_;
    return "[SET > $args]";
});
has 'getter_test' => (is => 'rw', getter => sub {
    my $self = shift;    
    return "[GET < $self->{getter_test}]";
});
before 'hook_target' => sub {
    my $self = shift;
    warn '[BEFORE1] hook_target';
}; 

before 'hook_target' => sub {
    my $self = shift;
    warn '[BEFORE2] hook_target';
}; 

after 'hook_target' => sub {
    my $self = shift;
    my @args = @_;
    warn '[AFTER1] hook_target';
    wd \@args;
}; 

sub hook_target {
    my @args = @_;
    warn '>>>> hook_target';
    wd \@args;
    warn '<<<<';
}

#sub NEW {
#    warn 'NEW';
#    return undef;
#}

#sub BUILD {
#    warn 'BUILD';
#}

#sub BUILDARGS {
#    my ($self, %args) = @_;
#    return \%args;
#}

1;
