package Devel::FindPerl;
{
  $Devel::FindPerl::VERSION = '0.002';
}
use strict;
use warnings;

use Exporter 5.57 'import';
our @EXPORT_OK = qw/find_perl_interpreter/;

use Carp;
use Cwd;
use ExtUtils::Config;
use File::Spec;

sub find_perl_interpreter {
	my $config = shift || ExtUtils::Config->new;

	my $perl          = $^X;
	return VMS::Filespec::vmsify($perl) if $^O eq 'VMS';
	my $perl_basename = File::Basename::basename($perl);

	my @potential_perls;

	# Try 1, Check $^X for absolute path
	push @potential_perls, $perl if File::Spec->file_name_is_absolute($perl);

	# Try 2, Check $^X for a valid relative path
	my $abs_perl = File::Spec->rel2abs($perl);
	push @potential_perls, $abs_perl;

	# Try 3, Last ditch effort: These two option use hackery to try to locate
	# a suitable perl. The hack varies depending on whether we are running
	# from an installed perl or an uninstalled perl in the perl source dist.
	if ($ENV{PERL_CORE}) {
		# Try 3.A, If we are in a perl source tree, running an uninstalled
		# perl, we can keep moving up the directory tree until we find our
		# binary. We wouldn't do this under any other circumstances.

		my $perl_src = Cwd::realpath(_perl_src());
		if (defined($perl_src) && length($perl_src)) {
			my $uninstperl = File::Spec->rel2abs(File::Spec->catfile($perl_src, $perl_basename));
			push @potential_perls, $uninstperl;
		}

	}
	else {
		# Try 3.B, First look in $Config{perlpath}, then search the user's
		# PATH. We do not want to do either if we are running from an
		# uninstalled perl in a perl source tree.

		push @potential_perls, $config->get('perlpath');
		push @potential_perls, map { File::Spec->catfile($_, $perl_basename) } File::Spec->path();
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
	my @paths = map File::Basename::dirname($_), @potential_perls;
	die "Can't locate the perl binary used to run this script in (@paths)\n";
}

# if building perl, perl's main source directory
sub _perl_src {
	# N.B. makemaker actually searches regardless of PERL_CORE, but
	# only squawks at not finding it if PERL_CORE is set

	return unless $ENV{PERL_CORE};

	my $updir = File::Spec->updir;
	my $dir	 = File::Spec->curdir;

	# Try up to 10 levels upwards
	for (0..10) {
		if (
			-f File::Spec->catfile($dir,"config_h.SH")
			&&
			-f File::Spec->catfile($dir,"perl.h")
			&&
			-f File::Spec->catfile($dir,"lib","Exporter.pm")
		) {
			return Cwd::realpath( $dir );
		}

		$dir = File::Spec->catdir($dir, $updir);
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
	push @cmd, '-I' . File::Spec->catdir(File::Basename::dirname($perl), 'lib') if $ENV{PERL_CORE};

	push @cmd, qw(-MConfig=myconfig -e print -e myconfig);
	open my $fh, '-|', @cmd or return;
	my $myconfig = join '', <$fh>;
	close $fh or return;
	return $myconfig eq Config->myconfig;
}

1;

#ABSTRACT: Find the path to your perl


__END__
=pod

=head1 NAME

Devel::FindPerl - Find the path to your perl

=head1 VERSION

version 0.002

=head1 DESCRIPTION

This module tries to find the path to the currently running perl.

=head1 FUNCTIONS

=head2 find_perl_interpreter

This function will try really really hard to find the path to the perl running your program. I should be able to find it in most circumstances. Do note that the result of this function is not cached, as it might be invalidated by for example a change of directory.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>, Randy Sims <randys@thepierianspring.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Randy Sims, Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
