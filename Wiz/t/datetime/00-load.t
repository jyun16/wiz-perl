#!/usr/bin/perl

use lib qw(../../lib);
use Wiz::Test qw/no_plan/;

chtestdir;

BEGIN{ use_ok "Wiz::DateTime" };
BEGIN{ use_ok "Wiz::DateTime::Unit" };
BEGIN{ use_ok "Wiz::DateTime::Delta" };
BEGIN{ use_ok "Wiz::DateTime::Parser" };
BEGIN{ use_ok "Wiz::DateTime::Formatter" };
