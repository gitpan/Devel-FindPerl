#! perl

use strict;
use warnings;

use Test::More;

use Capture::Tiny 'capture';
use Config;
use Devel::FindPerl 'find_perl_interpreter';

my $perl = find_perl_interpreter;

is(capture { system $perl, qw(-MConfig=myconfig -e print -e myconfig) }, Config->myconfig, 'Config of found perl equals current perl');

done_testing;
