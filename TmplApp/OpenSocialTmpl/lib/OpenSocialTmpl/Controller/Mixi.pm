package OpenSocialTmpl::Controller::Mixi;

use Wiz::Noose;
use OAuth::Lite::SignatureMethod::RSA_SHA1;
use OAuth::Lite::Util qw(create_signature_base_string);

use OpenSocialTmpl::Util qw(load_file4js);

extends qw(
    Wiz::Web::Framework::Controller::Root
);

our $SESSION_NAME = __PACKAGE__;
our $SNS_NAME = 'mixi';

sub index {
    my $self = shift;
    my ($c) = @_;
}

sub gadget {
    my $self = shift;
    my ($c) = @_;
    $c->stash->{conf} = $c->conf;
    $c->stash->{load_tt4js} = sub {
        return load_file4js($c->stash->{template_base} . "include/$SNS_NAME/canvas/" . shift() . '.tt');
    }
}

sub save_input_form {
    my $self = shift;
    my ($c) = @_;
    my $p = $c->req->params;
    $c->res->body('ok');
    my $mixi = $c->app_conf('mixi');
    wd $p;

    my $req = Net::OAuth->request('request token')->from_hash($p, consumer_secret => $mixi->{consumer_secret});

    warn $req->verify;


}

sub load_input_form {
    my $self = shift;
    my ($c) = @_;

}

1;
