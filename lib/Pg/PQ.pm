package Pg::PQ;

our $VERSION = '0.01';

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);

our @EXPORT_OK = ();

require XSLoader;
XSLoader::load('Pg::PQ', $VERSION);

package Pg::PQ::Conn;
use Carp;

sub new {
    my $class = shift;
    connectdb(@_);
}

sub start {
    my $class = shift;
    connectStart(@_);
}

sub DESTROY {
    my $self = shift;
    $self->finish if $$self;
}

sub getssl { croak "Pg::PQ::Conn::getssl not implemented" }

1;

__END__

=head1 NAME

Pg::PQ - Perl wrapper for PostgreSQL libpq

=head1 SYNOPSIS

  use Pg::PQ;
  blah blah blah

=head1 DESCRIPTION

=head2 Pg::PQ::Conn

=over 4

=item $dbc = Pg::PQ::Conn->new($conninfo)

wrapper method for libpq PQconnectdb

=item $dbc = Pg::PQ::Conn->start($conninfo)

wrapper method for libpq PQconnectStart

=item $dbc->db

=item $dbc->user

=item $dbc->pass

=item $dbc->host

=item $dbc->port

=item $dbc->options

=item $dbc->status

=item $dbc->transactionStatus

=item $dbc->parameterStatus

=item $dbc->protocolVersion

=item $dbc->serverVersion

=item $dbc->errorMessage

=item $dbc->socket

=item $dbc->backendPID

=item $dbc->connectionNeedsPassword

=item $dbc->connectionUsedPassword

=item $dbc->finish

=item $dbc->reset

=item $dbc->resetStart

=item $dbc->resetPoll

=item $dbc->trace

=item $dbc->untrace

=item $dbc->exec

=item $dbc->prepare

=item $dbc->execPrepared

=item $dbc->getCancel

=item $dbc->notifies

=item $dbc->makeEmptyResult

=item $dbc->escapeString

=item $dbc->sendQuery

=item $dbc->getResult

=item $dbc->consumeInput

=item $dbc->isBusy

=item $dbc->setnonblocking

=item $dbc->isnonblocking

=item $dbc->flush







=back

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Salvador Fandino, E<lt>salva@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Salvador Fandino

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
