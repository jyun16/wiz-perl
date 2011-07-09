package MobileTmpl;

use strict;

use Wiz::Constant qw(:common);
use Mobile::Wiz::Web::Framework qw(framework_load);

our %CONFIG = (
    max_request_size        => 12_800_000,
    custom_error            => {
        404     => 'not_found.tt',
        500     => 'error.tt',
        default => 'error.tt',
    },
    use_secure_token    => TRUE,
    TT  => {
    },
);

framework_load;

1;
