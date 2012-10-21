package Devel::FindPerl;
{
  $Devel::FindPerl::VERSION = '0.006';
}
use strict;
use warnings;

use Exporter 5.57 'import';
our @EXPORT_OK = qw/find_perl_interpreter/;

use Carp q/carp/;
use Cwd q/realpath/;
use ExtUtils::Config 0.007;
use File::Basename qw/basename dirname/;
use File::Spec::Functions qw/catfile catdir rel2abs file_name_is_absolute updir curdir path/;
use IPC::Open2 qw/open2/;

my %perl_for;
sub find_perl_interpreter {
	my $config = shift || ExtUtils::Config->new;
	my $key = $config->serialize;
	return $perl_for{$key} ||= _discover_perl_interpreter($config);
}

sub _discover_perl_interpreter {
	my $config = shift;

	my $perl          = $^X;
	return VMS::Filespec::vmsify($perl) if $^O eq 'VMS';
	my $perl_basename = basename($perl);

	my @potential_perls;

	# Try 1, Check $^X for absolute path
	push @potential_perls, file_name_is_absolute($perl) ? $perl : rel2abs($perl);

	# Try 2, Last ditch effort: These two option use hackery to try to locate
	# a suitable perl. The hack varies depending on whether we are running
	# from an installed perl or an uninstalled perl in the perl source dist.
	if ($ENV{PERL_CORE}) {
		# Try 3.A, If we are in a perl source tree, running an uninstalled
		# perl, we can keep moving up the directory tree until we find our
		# binary. We wouldn't do this under any other circumstances.

		my $perl_src = realpath(_perl_src());
		if (defined($perl_src) && length($perl_src)) {
			my $uninstperl = rel2abs(catfile($perl_src, $perl_basename));
			push @potential_perls, $uninstperl;
		}

	}
	else {
		# Try 2.B, First look in $Config{perlpath}, then search the user's
		# PATH. We do not want to do either if we are running from an
		# uninstalled perl in a perl source tree.

		push @potential_perls, $config->get('perlpath');
		push @potential_perls, map { catfile($_, $perl_basename) } path();
	}

	# Now that we've enumerated the potential perls, it's time to test
	# them to see if any of them match our configuration, returning the
	# absolute path of the first successful match.
	my $exe = $config->get('exe_ext');
	foreach my $thisperl (@potential_perls) {
		$thisperl .= $exe if length $exe and $thisperl !~ m/$exe$/i;
		return $thisperl if -f $thisperl && _perl_is_same($thisperl);
	}

	# We've tried all alternatives, and didn't find a perl that matches
	# our configuration. Throw an exception, and list alternatives we tried.
	my @paths = map { dirname($_) } @potential_perls;
	die "Can't locate the perl binary used to run this script in (@paths)\n";
}

# if building perl, perl's main source directory
sub _perl_src {
	# N.B. makemaker actually searches regardless of PERL_CORE, but
	# only squawks at not finding it if PERL_CORE is set

	return unless $ENV{PERL_CORE};

	my $updir = updir;
	my $dir	 = curdir;

	# Try up to 10 levels upwards
	for (0..10) {
		if (
			-f catfile($dir,"config_h.SH")
			&&
			-f catfile($dir,"perl.h")
			&&
			-f catfile($dir,"lib","Exporter.pm")
		) {
			return realpath($dir);
		}

		$dir = catdir($dir, $updir);
	}

	carp "PERL_CORE is set but I can't find your perl source!\n";
	return; # return empty string if $ENV{PERL_CORE} but can't find dir ???
}

sub _perl_is_same {
	my $perl = shift;

	my @cmd = $perl;

	# When run from the perl core, @INC will include the directories
	# where perl is yet to be installed. We need to reference the
	# absolute path within the source distribution where it can find
	# it's Config.pm This also prevents us from picking up a Config.pm
	# from a different configuration that happens to be already
	# installed in @INC.
	push @cmd, '-I' . catdir(dirname($perl), 'lib') if $ENV{PERL_CORE};
	push @cmd, qw(-MConfig=myconfig -e print -e myconfig);

	my $pid = open2(my($in, $out), @cmd);
	binmode $in, ':crlf' if $^O eq 'MSWin32';
	my $ret = do { local $/; <$in> };
	waitpid $pid, 0;
	return $ret eq Config->myconfig;
}

1;

#ABSTRACT: Find the path to your perl


__END__
=pod

=head1 NAME

Devel::FindPerl - Find the path to your perl

=head1 VERSION

version 0.006

=head1 DESCRIPTION

This module tries to find the path to the currently running perl.

=head1 FUNCTIONS

=head2 find_perl_interpreter($config = ExtUtils::Config->new)

This function will try really really hard to find the path to the perl running your program. I should be able to find it in most circumstances. Note that the result of this function will be cached for any serialized value of C<$config>.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>, Randy Sims <randys@thepierianspring.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Randy Sims, Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

