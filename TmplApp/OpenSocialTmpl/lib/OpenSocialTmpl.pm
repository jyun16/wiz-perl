package OpenSocialTmpl;

use strict;

use Wiz::Dumper;
use Wiz::Constant qw(:common);
use Wiz::Web::Framework qw(framework_load);

our %CONFIG = (
    title   => 'OpenSocialTest',
    author  => 'jn',
    email   => 'jyun16@gmail.com',
    max_request_size        => 12_800_000,
    custom_error            => {
        404     => 'not_found.tt',
        500     => 'error.tt',
        default => 'error.tt',
    },
    actions => [qw(
        show_profile
        show_friends
        input_form
        app_data
    )],
    use_secure_token    => FALSE,
    TT  => {
    },
);

framework_load;

1;
