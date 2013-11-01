#! perl -T

use strict;
use warnings;

use Test::More;

use Config;
use Devel::FindPerl qw/find_perl_interpreter perl_is_same/;

my $perlpath = join '', @Config{qw/perlpath exe_ext/};
plan(skip_all => "Perl not in perlpath '$perlpath'") unless -x $perlpath and perl_is_same($perlpath);
plan(skip_all => 'Taint test can\'t be run from uninstalled perl') if $ENV{PERL_CORE};
plan(skip_all => 'Testrun without taint mode') if not $^T;

my $interpreter = do {
	local $SIG{__WARN__} = sub { fail("Got a warning during find_perl_interpreter") };
	find_perl_interpreter();
};
is($interpreter, $perlpath, 'Always find $Config{perlpath} under tainting');

done_testing;
