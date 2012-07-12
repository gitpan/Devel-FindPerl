
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Find the path to your perl",
  "AUTHOR" => "Leon Timmermans <leont\@cpan.org>, Randy Sims <randys\@thepierianspring.org>",
  "BUILD_REQUIRES" => {
    "Capture::Tiny" => 0,
    "Config" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Devel-FindPerl",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Devel::FindPerl",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Cwd" => 0,
    "Exporter" => "5.57",
    "ExtUtils::Config" => 0,
    "File::Spec" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.002",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);


