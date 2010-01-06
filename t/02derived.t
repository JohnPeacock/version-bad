#! /usr/local/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test::More qw/no_plan/;
use File::Temp qw/tempfile/;
my $Verbose;

BEGIN {
    require "t/coretests.pm";
    use_ok("version", 0.79);
    # If we made it this far, we are ok.
}

use lib qw/./;

package version::Bad;
use base 'version';
sub new { my($self,$n)=@_;  bless \$n, $self }

package main;

my $warning;
local $SIG{__WARN__} = sub { $warning = $_[0] };
# dummy up a legal module for testing RT#19017
my ($fh, $filename) = tempfile('tXXXXXXX', SUFFIX => '.pm', UNLINK => 1);
(my $package = basename($filename)) =~ s/\.pm$//;
print $fh <<"EOF";
# This is an empty subclass
package $package;
use base 'version';
use vars '\$VERSION';
\$VERSION=0.001;
EOF
close $fh;

sub main_reset {
    delete $main::INC{'$package'};
    undef &qv; undef *::qv; # avoid 'used once' warning
    undef &declare; undef *::declare; # avoid 'used once' warning
}

diag "Tests with empty derived class"  if $Verbose;

use_ok($package, 0.001);
my $testobj = $package->new(1.002_003);
isa_ok( $testobj, $package );
ok( $testobj->numify == 1.002003, "Numified correctly" );
ok( $testobj->stringify eq "1.002003", "Stringified correctly" );
ok( $testobj->normal eq "v1.2.3", "Normalified correctly" );

my $verobj = version::->new("1.2.4");
ok( $verobj > $testobj, "Comparison vs parent class" );

BaseTests($package, "new", "qv");
main_reset;
use_ok($package, 0.001, "declare");
BaseTests($package, "new", "declare");
main_reset;
use_ok($package, 0.001);
BaseTests($package, "parse", "qv");
main_reset;
use_ok($package, 0.001, "declare");
BaseTests($package, "parse", "declare");

diag "tests with bad subclass"  if $Verbose;
$testobj = version::Bad->new(1.002_003);
isa_ok( $testobj, "version::Bad" );
eval { my $string = $testobj->numify };
like($@, qr/Invalid version object/,
    "Bad subclass numify");
eval { my $string = $testobj->normal };
like($@, qr/Invalid version object/,
    "Bad subclass normal");
eval { my $string = $testobj->stringify };
like($@, qr/Invalid version object/,
    "Bad subclass stringify");
eval { my $test = ($testobj > 1.0) };
like($@, qr/Invalid version object/,
    "Bad subclass vcmp");
