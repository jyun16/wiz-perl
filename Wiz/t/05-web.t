#!/usr/bin/perl

use lib qw(../lib);

package main;

use Wiz::Test qw(no_plan);
use Wiz::Web qw(:all);

is uri_escape("hoge://fuga.foo.bar?xxx=XXX"),
    'hoge%3A%2F%2Ffuga.foo.bar%3Fxxx%3DXXX', q|uri_escape|;

is uri_unescape("hoge%3A%2F%2Ffuga.foo.bar%3Fxxx%3DXXX"),
    'hoge://fuga.foo.bar?xxx=XXX', q|uri_unescape|;

is_deeply query2hash("hoge=fuga&foo=bar"),
    { hoge => 'fuga', foo => 'bar' }, q|query2hash|;

