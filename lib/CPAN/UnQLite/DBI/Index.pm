# $Id: Index.pm 42 2013-06-29 20:44:17Z stro $

package CPAN::UnQLite::DBI::Index;
use strict;
use warnings;

our $VERSION = '0.01_01';

use CPAN::UnQLite::DBI qw($dbh);
use parent 'CPAN::UnQLite::DBI';

package CPAN::UnQLite::DBI::Index::info;
use parent 'CPAN::UnQLite::DBI::Index';
use CPAN::UnQLite::DBI qw($dbh);

package CPAN::UnQLite::DBI::Index::chaps;
use parent 'CPAN::UnQLite::DBI::Index';
use CPAN::UnQLite::DBI qw($dbh);

package CPAN::UnQLite::DBI::Index::mods;
use parent 'CPAN::UnQLite::DBI::Index';
use CPAN::UnQLite::DBI qw($dbh);

package CPAN::UnQLite::DBI::Index::dists;
use parent 'CPAN::UnQLite::DBI::Index';
use CPAN::UnQLite::DBI qw($dbh);

sub fetch_ids {
  my $self = shift;
  my $sql = sprintf(qq{SELECT %s,%s,%s FROM %s},
                    $self->{id}, $self->{name}, 'dist_vers',
                    $self->{table});
  my $sth = $dbh->prepare($sql) or do {
    $self->db_error();
    return;
  };
  $sth->execute() or do {
    $self->db_error($sth);
    return;
  };
  my ($ids, $versions);
  while (my ($id, $key, $vers) = $sth->fetchrow_array()) {
    $ids->{$key} = $id;
    $versions->{$key} = $vers;
  }
  $sth->finish;
  undef $sth;
  return ($ids, $versions);
}

package CPAN::UnQLite::DBI::Index::auths;
use parent 'CPAN::UnQLite::DBI::Index';
use CPAN::UnQLite::DBI qw($dbh);

package CPAN::UnQLite::DBI::Index;
use CPAN::UnQLite::DBI qw($tables);
use CPAN::UnQLite::DBI qw($dbh);

sub fetch_ids {
  my $self = shift;
  my $sql = sprintf(qq{SELECT %s,%s from %s},
                    $self->{id}, $self->{name}, $self->{table});
  my $sth = $dbh->prepare($sql) or do {
    $self->db_error();
    return;
  };
  $sth->execute() or do {
    $self->db_error($sth);
    return;
  };
  my $ids;
  while (my ($id, $key) = $sth->fetchrow_array()) {
    $ids->{$key} = $id;
  }
  $sth->finish;
  undef $sth;
  return $ids;
}

sub schema {
  my ($self, $data) = @_;
  my $schema = '';
  foreach my $type (qw(primary other)) {
    foreach my $column (keys %{$data->{$type}}) {
      $schema .= $column . ' ' . $data->{$type}->{$column} . ", ";
    }
  }
  $schema =~ s{, $}{};
  return $schema;
}

sub create_index {
  my ($self, $data) = @_;
  my $key = $data->{key};
  my $table = $self->{table};
  return 1 unless (defined $key and ref($key) eq 'ARRAY');
  foreach my $index(@$key) {
    my $id_name = 'ix_' . $table . '_' . $index;
    $id_name =~ s/\(\s*\d+\s*\)//;
    my $sql = 'CREATE INDEX ' . $id_name . ' ON ' .
      $table . '( ' . $index . ' )';
    my $sth = $dbh->prepare($sql);
    $sth->execute() or do {
      $self->db_error($sth);
      return;
    };
    $sth->finish;
    undef $sth;
  }
  return 1;
}

sub drop_table {
  my $self = shift;
  my $table = $self->{table};
  my $sql = qq{SELECT name FROM sqlite_master } .
    qq{ WHERE type='table' AND name=?};
  my $sth = $dbh->prepare($sql);
  $sth->execute($table);
  if (defined $sth->fetchrow_array) {
    $dbh->do(qq{drop table $table}) or do {
      $self->db_error($sth);
      return;
    };
  }
  $sth->finish;
  undef $sth;
  return 1;
}

sub create_table {
  my ($self, $schema) = @_;
  return unless $schema;
  my $sql = sprintf(qq{CREATE TABLE %s (%s)}, $self->{table}, $schema);
  my $sth = $dbh->prepare($sql);
  $sth->execute() or do {
    $self->db_error($sth);
    return;
  };
  $sth->finish;
  undef $sth;
  return 1;
}

sub create_tables {
  my ($self, %args) = @_;
  return unless $args{setup};
  my $objs = $self->{objs};
  $dbh->{AutoCommit} = 0;
  foreach my $table(keys %$objs) {
    next unless my $schema = $self->schema($tables->{$table});
    my $obj = $objs->{$table};
    $obj->drop_table or return;
    $obj->create_table($schema) or return;
    $obj->create_index($tables->{$table}) or return;
  }
  $dbh->{AutoCommit} = 1;
  return 1;
}

sub sth_insert {
  my ($self, $fields) = @_;
  my $flds = join ',', @{$fields};
  my $vals = join ',', map { '?' } @{$fields};
  my $sql = sprintf(qq{INSERT INTO %s (%s) VALUES (%s)},
                    $self->{table}, $flds, $vals);

  my $sth = $dbh->prepare($sql) or do {
    $self->db_error();
    return;
  };
  return $sth;
}

sub sth_update {
  my ($self, $fields, $id, $rep_id) = @_;
  my $set = join ',', map { "$_=?" } @{$fields};
  my $sql = sprintf(qq{UPDATE %s SET %s WHERE %s = %s},
                    $self->{table}, $set, $self->{id}, $id);
  $sql .= qq { AND rep_id = $rep_id } if ($rep_id);
  my $sth = $dbh->prepare($sql) or do {
    $self->db_error();
    return;
  };
  return $sth;
}

sub sth_delete {
  my ($self, $table_id, $rep_id) = @_;
  my $sql = sprintf(qq{DELETE FROM %s where %s = ?},
                    $self->{table}, $table_id);
  $sql .= qq { AND rep_id = $rep_id } if ($rep_id);
  my $sth = $dbh->prepare($sql) or do {
    $self->db_error();
    return;
  };
  return $sth;
}

1;

=head1 NAME

CPAN::UnQLite::DBI::Index - DBI information for indexing the CPAN::UnQLite database

=head1 DESCRIPTION

This module provides various methods for L<CPAN::UnQLite::Index> in
indexing and populating the database from the index files.

=over

=item C<create_tables>

This creates the database tables.

=item C<drop_table>

This drops a table.

=item C<sth_insert>

This returns an C<$sth> statement handle for inserting
values into a table.

=item C<sth_update>

This returns an C<$sth> statement handle for updating
values into a table.

=item C<sth_delete>

This returns an C<$sth> statement handle for deleting
values from a table.

=back

=head1 SEE ALSO

L<CPAN::UnQLite::Index>

=cut

