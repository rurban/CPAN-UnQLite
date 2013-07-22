use strict;
use warnings;
use Test::More;
BEGIN {plan tests => 4};
for (qw(CPAN::UnQLite::Index CPAN::UnQLite::Search CPAN::UnQLite CPAN::UnQLite::META)) {
  require_ok($_);
}
