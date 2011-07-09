use strict;
use warnings;
use inc::Module::Install;

name('Wiz-Mobile');
author('Kato Atsushi <kato@adways.net>');
all_from('lib/Mobile/Wiz.pm');

requires
    'Class::Inspector'                   => 0,
    'Encode::JP::Mobile'                 => 0,
    'HTML::StickyQuery::DoCoMoGUID'      => 0,
    'HTTP::MobileAgent'                  => 0,
    'HTTP::MobileUserID'                 => 0,
    'HTTP::MobileAgent::Plugin::Charset' => 0,
    'WWW::MobileCarrierJP'               => 0,
;

auto_include;
auto_install;

WriteAll;
