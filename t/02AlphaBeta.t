# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 31;
BEGIN { use_ok('version::AlphaBeta') };

diag "Tests with base class" unless $ENV{PERL_CORE};
BaseTests("version::AlphaBeta");

#########################

package version::AlphaBeta::Empty;
use vars qw($VERSION @ISA);
use Exporter;
use version 0.30;
@ISA = qw(Exporter version::AlphaBeta);
$VERSION = 0.01;

package main;
diag "Tests with empty derived class" unless $ENV{PERL_CORE};
BaseTests("version::AlphaBeta::Empty");

sub BaseTests {

    my $class = shift;

    my $v = new $class "1.2rc1";
    ok ("v1.2rc1" eq "$v", "Release candidate: [$v]");
    
    $v = new $class "1.3a";
    ok ("v1.3a" eq "$v", "Alpha: [$v]");
    ok ("v1.3a" eq  $v, "v1.3a eq Alpha");
    ok ("v1.3a" == $v, "v1.3a == Alpha");
    ok ($v->is_alpha, "$v->is_alpha");
    
    $v = new $class "1.2b";
    ok ("v1.2b" eq "$v", "Beta: [$v]");
    ok ("v1.2b" eq  $v, "v1.2b eq Beta");
    ok ("v1.2b" == $v, "v1.2b == Beta");
    ok ($v->is_beta, "$v->is_beta");
    
    $v = new $class "v1.2";
    ok ("v1.2" eq "$v", "Release: [$v]");
    ok ("1.2a" < $v , "Alpha < Release");
    
    my $v2 = new $class "1.2rc1";
    ok ( $v > $v2 , "Release > Release Candidate ");
    ok ( $v2 > "1.2a", "Release Candidate > Alpha");
    
    eval { my $v3 = new $class "nothing" };
    like($@, qr/Illegal version string format/, substr($@,0,index($@," at ")) );
    eval { my $v3 = new $class "1.2.3" };
    like($@, qr/Illegal version string format/, substr($@,0,index($@," at ")) );
 }
