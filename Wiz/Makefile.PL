use strict;
use warnings;
use inc::Module::Install;

name('Wiz');

perl_version '5.8.1';
version '1.0.3';
author('Junichiro NAKAMURA <jyun16@gmail.com>');

requires
    'Test::More'                        => 0,
    'Spiffy'                            => 0,
    'Test::Base'                        => 0,
    'Tie::Hash::Indexed'                => 0,
    'Proc::ProcessTable'                => 0,
    'Time::Zone'                        => 0,
    'Time::TAI64'                       => 0,
    'DateTime'                          => 0,
    'IO::Prompt'                        => 0,
    'IO::Scalar'                        => 0,
    'Params::Validate'                  => 0,
    'DateTime::Locale'                  => 0,
    'DateTime::TimeZone'                => 0,
    'DateTime::Duration'                => 0,
    'Digest::MD5'                       => 0,
    'Tie::File'                         => 0,
    'IO::Scalar'                        => 0,
    'File::Basename'                    => 0,
    'File::Path'                        => 0,
    'Cwd'                               => 0,
    'File::Copy'                        => 0,
    'IO::Handle'                        => 0,
    'MIME::Lite'                        => 0,
    'MIME::Lite::TT'                    => 0,
    'Readonly'                          => 0,
    'List::MoreUtils'                   => 0,
    'YAML'                              => 0,
    'YAML::Syck'                        => 0,
    'I18N::LangTags'                    => 0,
    'I18N::LangTags::Detect'            => 0,
    'Digest::SHA'                       => 0,
    'Sys::Syslog'                       => 0,
    'File::Mirror'                      => 0,
    'Class::Singleton'                  => 0,
    'JSON::XS'                          => 0,
    'Clone'                             => 0,
    'Template'                          => 0,
    'Template::Plugin::AutoLink'        => 0,
    'Net::IP::CMatch'                   => 0,
    'WebService::Simple'                => 0,
    'Module::Pluggable'                 => 0,
    'DBI'                               => 0,
    'Math::Random::MT::Auto'            => 0,
#    'Data::Feed'                        => 0,
    'Feed::Find'                        => 0,
    'Unicode::Japanese'                 => 0,
    'Devel::Symdump'                    => 0,
#    'HTTP::MobileAgent'                 => 0,
#    'HTTP::MobileUserID'                => 0,
#    'Net::SMTP::TLS'                    => 0,
    'Email::MIME'                       => 0,
    'Mail::POP3Client'                  => 0,
    'Cache::Memcached::Fast'            => 0,
    'HTML::Scrubber'                    => 0,
    'Crypt::OpenSSL::Random'            => 0,
#    'XML::Feed'                         => 0,
    'Any::Moose'                        => 0,
    'OAuth::Lite'                       => 0,
#    'Data::Dumper::Names'               => 0,
#    'HTML::TreeBuilder'                 => 0,
#    'DateTime::Format::Atom'            => 0,
#    'DateTime::Format::RSS'             => 0,
#    'DateTime::Format::DateParse'       => 0,
# for FW
    'File::MimeInfo'                    => 0,
    'AnyEvent'                          => 0,
    'HTTP::Parser'                      => 0,
    'HTTP::Request::Params'             => 0,
    'Proc::Fork'                        => 0,
    'IO::Interface'                     => 0,
    'CGI::Simple::Cookie'               => 0,
    'File::Remove'                      => 0,
    'Data::Util'                        => 0,
    'XML::Simple'                       => 0,
;

auto_include;
auto_install;

WriteAll;
