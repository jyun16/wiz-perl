package MobileOpenSocialTmpl;

use strict;

use Wiz::Constant qw(:common);
use Mobile::Wiz::Web::Framework qw(framework_load mobile_only force_sjis);

our %CONFIG = (
    title   => 'Mobile Open Social Test(MOST)',
    author  => 'jn',
    email   => 'jyun16@gmail.com',
    max_request_size        => 12_800_000,
    custom_error            => {
        404     => 'not_found.tt',
        500     => 'error.tt',
        default => 'error.tt',
    },
    use_secure_token    => FALSE,
    TT  => {
    },
    dir     => {
        qr  => 'qr',
    },
);

framework_load;
#mobile_only;
#force_sjis;

1;
