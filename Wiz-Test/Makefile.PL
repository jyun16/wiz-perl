use strict;
use warnings;
use inc::Module::Install;

name('Wiz-Test');
author('Kato Atsushi <kato@adways.net>');
all_from('lib/Wiz/Test.pm');

auto_include;
auto_install;

WriteAll;
