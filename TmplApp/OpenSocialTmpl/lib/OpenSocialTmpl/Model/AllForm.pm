package OpenSocialTmpl::Model::AllForm;

use Wiz::Noose;
use Wiz::Constant qw(:common);
use Wiz::Web::Framework::Model::Filters qw(SHA512_BASE64);

extends qw(
    Wiz::Web::Framework::Model
);

our @CREATE = qw(
member_id
text
password
textarea
select1
multi_select
radio1
radio2
checkbox
email
first_name
last_name
date1
date2
time1
datetime1
created_time
);
our @MODIFY = @CREATE;
our @SEARCH = ('id', @CREATE);
our $PRIMARY_KEY = 'id';
our %CREATE_FILTERS = (
    password    => SHA512_BASE64,
);

=head1 AUTHOR

=head1 COPYRIGHT & LICENSE

=cut

1;
