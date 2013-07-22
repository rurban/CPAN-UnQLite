use strict;
use warnings;
use Test::More;
use UnQLite;
BEGIN {plan tests => 7};

my $db_name = 't/dot-cpan/cpandb.db';

my $dbh = UnQLite->open($db_name, UnQLite::OPEN_READWRITE|UnQLite::OPEN_CREATE)
  or die "Cannot connect to $db_name";
ok($dbh);
isa_ok($dbh, 'UnQLite');
my @tables = qw(mods auths chaps dists info);
for my $table(@tables) {
  if ($dbh->kv_fetch($table)) {
    $dbh->kv_delete($table);
    pass("Drop $table");
  } else {
    pass("Skip $table");
  }
}
undef $dbh;
