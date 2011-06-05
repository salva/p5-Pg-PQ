package Pg::PQ;

our $VERSION = '0.01';

use 5.010001;
use strict;
use warnings;

require XSLoader;
XSLoader::load('Pg::PQ', $VERSION);

use Exporter qw(import);

our %EXPORT_TAGS;
our @EXPORT_OK = map @$_, values %EXPORT_TAGS;
$EXPORT_TAGS{all} = [@EXPORT_OK];

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

package Pg::PQ::Result;

sub DESTROY {
    my $self = shift;
    $self->clear if $$self;
}

1;

__END__

=head1 NAME

Pg::PQ - Perl wrapper for PostgreSQL libpq

=head1 SYNOPSIS

  use Pg::PQ qw(:);
  my $dbc = Pg::PQ::Conn->new("dbname=test host=dbserver");
  $dbc->status 

=head1 DESCRIPTION

=head2 Pg::PQ::Conn class

These are the methods available from the class Pg::PQ::Conn:

=over 4

=item $dbc = Pg::PQ::Conn->new($conninfo)

Creates a new Pg::PQ::Conn and connects to the database defined by the
parameters given in C<$conninfo>.

Accepted parameters:

=over 4

=item host

Name of host to connect to. If this begins with a slash, it specifies
Unix-domain communication rather than TCP/IP communication; the value
is the name of the directory in which the socket file is stored. The
default behavior when host is not specified is to connect to a
Unix-domain socket in C</tmp> (or whatever socket directory was
specified when PostgreSQL was built). On machines without Unix-domain
sockets, the default is to connect to localhost.

=item hostaddr

Numeric IP address of host to connect to. This should be in the
standard IPv4 address format, e.g., C<172.28.40.9>. If your machine
supports IPv6, you can also use those addresses. TCP/IP communication
is always used when a nonempty string is specified for this parameter.

Using C<hostaddr> instead of C<host> allows the application to avoid a
host name look-up, which might be important in applications with time
constraints. However, a host name is required for Kerberos, GSSAPI, or
SSPI authentication, as well as for full SSL certificate
verification.

The following rules are used:

=over 4

=item *

If C<host> is specified without C<hostaddr>, a host name lookup
occurs.

=item *

If C<hostaddr> is specified without C<host>, the value for C<hostaddr>
gives the server address. The connection attempt will fail in any of
the cases where a host name is required.

=item *

If both C<host> and C<hostaddr> are specified, the value for
C<hostaddr> gives the server address. The value for C<host> is ignored
unless needed for authentication or verification purposes, in which
case it will be used as the host name.

Note that authentication is likely to fail if C<host> is not the name
of the machine at C<hostaddr>. Also, note that C<host> rather than
C<hostaddr> is used to identify the connection in C<~/.pgpass> (see
Section 31.14 of the PostgreSQL documentation).

=item *

Without either a host name or host address, libpq will connect using a
local Unix-domain socket; or on machines without Unix-domain sockets,
it will attempt to connect to localhost.

=back

=item port

Port number to connect to at the server host, or socket file name
extension for Unix-domain connections.

=item dbname

The database name. Defaults to be the same as the user name.

=item user

PostgreSQL user name to connect as. Defaults to be the same as the
operating system name of the user running the application.

=item password

Password to be used if the server demands password authentication.

=item connect_timeout

Maximum wait for connection, in seconds (write as a decimal integer
string). Zero or not specified means wait indefinitely. It is not
recommended to use a timeout of less than 2 seconds.

=item options

Adds command-line options to send to the server at run-time. For
example, setting this to -c geqo=off sets the session's value of the
geqo parameter to off. For a detailed discussion of the available
options, consult Chapter 18.  application_name

Specifies a value for the application_name configuration parameter.

=item fallback_application_name

Specifies a fallback value for the C<application_name> configuration
parameter. This value will be used if no value has been given for
application_name via a connection parameter or the C<PGAPPNAME>
environment variable.

Specifying a fallback name is useful in generic utility programs that
wish to set a default application name but allow it to be overridden
by the user.

=item keepalives

Controls whether client-side TCP keepalives are used. The default
value is C<1>, meaning on, but you can change this to C<0>, meaning
off, if keepalives are not wanted.

This parameter is ignored for connections made via a Unix-domain
socket.

=item keepalives_idle

Controls the number of seconds of inactivity after which TCP should
send a keepalive message to the server. A value of zero uses the
system default. This parameter is ignored for connections made via a
Unix-domain socket, or if keepalives are disabled. It is only
supported on systems where the C<TCP_KEEPIDLE> or C<TCP_KEEPALIVE>
socket option is available, and on Windows; on other systems, it has
no effect.

=item keepalives_interval

Controls the number of seconds after which a TCP keepalive message
that is not acknowledged by the server should be retransmitted. A
value of zero uses the system default. This parameter is ignored for
connections made via a Unix-domain socket, or if keepalives are
disabled. It is only supported on systems where the C<TCP_KEEPINTVL>
socket option is available, and on Windows; on other systems, it has
no effect.

=item keepalives_count

Controls the number of TCP keepalives that can be lost before the
client's connection to the server is considered dead. A value of zero
uses the system default. This parameter is ignored for connections
made via a Unix-domain socket, or if keepalives are disabled. It is
only supported on systems where the C<TCP_KEEPINTVL> socket option is
available; on other systems, it has no effect.

=item sslmode

This option determines whether or with what priority a secure SSL
TCP/IP connection will be negotiated with the server. There are six
modes:

=over 4

=item disable

only try a non-SSL connection

=item allow

first try a non-SSL connection; if that fails, try an SSL connection

=item prefer (default)

first try an SSL connection; if that fails, try a non-SSL connection

=item require

only try an SSL connection

=item verify-ca

only try an SSL connection, and verify that the server certificate is
issued by a trusted CA

=item verify-full

only try an SSL connection, verify that the server certificate is
issued by a trusted CA and that the server host name matches that in
the certificate

=back

C<sslmode> is ignored for Unix domain socket communication. If
PostgreSQL is compiled without SSL support, using options C<require>,
C<verify-ca>, or C<verify-full> will cause an error, while options
C<allow> and C<prefer> will be accepted but libpq will not actually
attempt an SSL connection.

=item sslcert

This parameter specifies the file name of the client SSL certificate,
replacing the default C<~/.postgresql/postgresql.crt>. This parameter
is ignored if an SSL connection is not made.

=item sslkey

This parameter specifies the location for the secret key used for the
client certificate. It can either specify a file name that will be
used instead of the default C<~/.postgresql/postgresql.key>, or it can
specify a key obtained from an external "engine" (engines are OpenSSL
loadable modules). An external engine specification should consist of
a colon-separated engine name and an engine-specific key
identifier. This parameter is ignored if an SSL connection is not
made.

=item sslrootcert

This parameter specifies the name of a file containing SSL certificate
authority (CA) certificate(s). If the file exists, the server's
certificate will be verified to be signed by one of these
authorities. The default is C<~/.postgresql/root.crt>.

=item sslcrl

This parameter specifies the file name of the SSL certificate
revocation list (CRL). Certificates listed in this file, if it exists,
will be rejected while attempting to authenticate the server's
certificate. The default is C<~/.postgresql/root.crl>.

=item krbsrvname

Kerberos service name to use when authenticating with Kerberos 5 or
GSSAPI. This must match the service name specified in the server
configuration for Kerberos authentication to succeed. (See also
Section 19.3.5 and Section 19.3.3. of the PostgreSQL documentation).

=item gsslib

GSS library to use for GSSAPI authentication. Only used on
Windows. Set to gssapi to force libpq to use the GSSAPI library for
authentication instead of the default SSPI.

=item service

Service name to use for additional parameters. It specifies a service
name in C<pg_service.conf> that holds additional connection
parameters. This allows applications to specify only a service name so
connection parameters can be centrally maintained. See Section 31.15
of the PostgreSQL documentation.

If any parameter is unspecified, then the corresponding environment
variable (see Section 31.13 of the PostgreSQL documentation) is
checked. If the environment variable is not set either, then the
indicated built-in defaults are used.

If C<expand_dbname> is non-zero and dbname contains an C<=> sign, it
is taken as a conninfo string in exactly the same way as if it had
been passed to PQconnectdb(see below). Previously processed key words
will be overridden by key words in the conninfo string.

In general key words are processed from the beginning of these arrays
in index order. The effect of this is that when key words are
repeated, the last processed value is retained. Therefore, through
careful placement of the dbname key word, it is possible to determine
what may be overridden by a conninfo string, and what may not.

=back

See also
L<http://www.postgresql.org/docs/9.0/interactive/libpq-connect.html>.

Example:

  my $dbc = Pg::PQ::Conn->new("dbname=testdb user=jsmith passwd=jsmith11");

I<(This method wraps PQconnectdb)>

=item $dbc = Pg::PQ::Conn->start($conninfo)

Similar to C<new> but returns inmediately without waiting for the
network connection to the database and the protocol handshake to be
completed.

This method combined with C<pollStart> described below allows to
establish database connections asynchronously.

I<(This method wraps PQconnectStart)>

=item $poll_status = $dbc->connectPoll

Returns the polling status when connecting asynchronously to a
database. Returns any of the C<pgres_polling> constants (see
L</Constants> bellow). I<This method wraps PQconnectPoll>.

This method combined with C<start> are used to open a connection to a
database server such that your application's thread of execution is
not blocked on remote I/O whilst doing so. The point of this approach
is that the waits for I/O to complete can occur in the application's
main loop, rather than down inside PQconnectdbParams or PQconnectdb,
and so the application can manage this operation in parallel with
other activities.

Neither C<start> nor C<connectPoll> will block, so long as a number of
restrictions are met:

=over 4

=item *

The C<hostaddr> and C<host> parameters are used appropriately to
ensure that name and reverse name queries are not made. See the
documentation of these parameters under L</new> above for details.

=item *

If you call C<trace>, ensure that the stream object into which you
trace will not block.

=item *

You ensure that the socket is in the appropriate state before calling
C<connectPoll>, as described below.

=back

To begin a nonblocking connection request, call C<$dbc =
Pg::PQ-E<gt>start($conninfo)>. If C<$dbc> is undefined, then libpq has
been unable to allocate a new Pg::PQ::Conn object. Otherwise, a valid
Pg::PQ::Conn object is returned (though not yet representing a valid
connection to the database). On return from C<start>, call C<$status =
$dbc-E<gt>status>. If C<$status> equals C<CONNECTION_BAD>, C<start>
has failed.

If C<start> succeeds, the next stage is to poll libpq so that
it can proceed with the connection sequence.
Use C<$fd = $dbc-E<gt>socket> to obtain the descriptor of the socket
underlying the database connection. Loop thus: If
C<$dbc-E<gt>connectPoll> last returned C<PGRES_POLLING_READING>, wait
until the socket is ready to read (as indicated by C<select>, C<poll>,
or similar system function). Then call C<$dbc-E<gt>connectPoll>
again. Conversely, if C<$dbc-E<gt>connectPoll> last returned
C<PGRES_POLLING_WRITING>, wait until the socket is ready to write,
then call C<$dbc-E<gt>connectPoll> again. If you have yet to call
C<connectPoll>, i.e., just after the call to C<start>, behave as if it
last returned C<PGRES_POLLING_WRITING>. Continue this loop until
C<connectPoll> returns C<PGRES_POLLING_FAILED>, indicating the
connection procedure has failed, or C<PGRES_POLLING_OK>, indicating
the connection has been successfully made.

At any time during connection, the status of the connection can be
checked by calling C<$dbc-E<gt>status>. If this gives
C<CONNECTION_BAD>, then the connection procedure has failed; if it
gives C<CONNECTION_OK>, then the connection is ready. Both of these
states are equally detectable from the return value of C<connectPoll>,
described above. Other states might also occur during (and only
during) an asynchronous connection procedure. These indicate the
current stage of the connection procedure and might be useful to
provide feedback to the user for example. These statuses are:

=over 4

=item CONNECTION_STARTED

Waiting for connection to be made.

=item CONNECTION_MADE

Connection OK; waiting to send.

=item CONNECTION_AWAITING_RESPONSE

Waiting for a response from the server.

=item CONNECTION_AUTH_OK

Received authentication; waiting for backend start-up to finish.

=item CONNECTION_SSL_STARTUP

Negotiating SSL encryption.

=item CONNECTION_SETENV

Negotiating environment-driven parameter settings.

=back

Note that, although these constants will remain (in order to maintain
compatibility), an application should never rely upon these occurring
in a particular order, or at all, or on the status always being one of
these documented values. An application might do something like this:


  given($dbc->status) {
      when (CONNECTION_STARTED) {
          say "Connecting...";
      }
      when (CONNECTION_MADE) {
          say "Connected to server...";
      }
      ...
      default {
          say "Connecting...";
      }
  }

The C<connect_timeout> connection parameter is ignored when using
C<start> and C<connectPoll>; it is the application's responsibility to
decide whether an excessive amount of time has elapsed. Otherwise,
C<tart> followed by a C<connectPoll> loop is equivalent to
C<new>.

=item $dbc->db

Returns the database name.

=item $dbc->user

Returns the user name.

=item $dbc->pass

Returns the login password.

=item $dbc->host

Returns the name of the server

=item $dbc->port

Returns the remote port of the connection

=item $dbc->options

Return the options passed to the constructor

=item $dbc->status

Return the status of the connection

The status can be one of a number of values. However, only two of
these are seen outside of an asynchronous connection procedure:
C<CONNECTION_OK> and C<CONNECTION_BAD>. A good connection to the
database has the status C<CONNECTION_OK>. A failed connection attempt
is signaled by status C<CONNECTION_BAD>. Ordinarily, an OK status will
remain so until L</finish> (called implicitly by C<DESTROY>), but a
communications failure might result in the status changing to
C<CONNECTION_BAD> prematurely. In that case the application could try
to recover by calling L</reset>.

See the entry for L</start> and L</connectPoll> with regards to other
status codes that might be seen.

=item $dbc->transactionStatus

Returns the current in-transaction status of the server.

The status can be:

=over 4

=item PQTRANS_IDLE

Currently idle.

=item PQTRANS_ACTIVE

A command is in progress. This status is reported only when a query
has been sent to the server and not yet completed.

=item PQTRANS_INTRANS

Idle, in a valid transaction block.

=item PQTRANS_INERROR

Idle, in a failed transaction block.

=item PQTRANS_UNKNOWN

Is reported if the connection is bad.

=back

PostgreSQL documentation contains the following warning:

   Caution: C<transactionStatus> will give incorrect results when
   using a PostgreSQL 7.3 server that has the parameter autocommit set
   to off. The server-side autocommit feature has been deprecated and
   does not exist in later server versions.

=item $dbc->parameterStatus

Looks up a current parameter setting of the server.

Certain parameter values are reported by the server automatically at
connection startup or whenever their values change. C<parameterStatus>
can be used to interrogate these settings. It returns the current
value of a parameter if known, or C<undef> if the parameter is not
known.

Parameters reported as of the current release include:

  server_version, server_encoding, client_encoding, application_name,
  is_superuser, session_authorization, DateStyle, IntervalStyle,
  TimeZone, integer_datetimes and standard_conforming_strings.

  server_encoding, TimeZone, and integer_datetimes were not reported
  by releases before 8.0.

  standard_conforming_strings was not reported by releases before 8.1.

  IntervalStyle was not reported by releases before 8.4.

  application_name was not reported by releases before 9.0.

Note that C<server_version>, C<server_encoding> and
C<integer_datetimes> cannot change after startup.

Pre-3.0-protocol servers do not report parameter settings, but libpq
includes logic to obtain values for C<server_version> and
C<client_encoding> anyway. Applications are encouraged to use
C<parameterStatus> rather than ad hoc code to determine these values
(beware however that on a pre-3.0 connection, changing
C<client_encoding> via C<SET> after connection startup will not be
reflected by C<parameterStatus>). For C<server_version>, see also
C<serverVersion>, which returns the information in a numeric form that
is much easier to compare against.

If no value for C<standard_conforming_strings> is reported,
applications can assume it is off, that is, backslashes are treated as
escapes in string literals. Also, the presence of this parameter can
be taken as an indication that the escape string syntax (C<E'...'>) is
accepted.

=item $dbc->protocolVersion

Interrogates the frontend/backend protocol being used.

Applications might wish to use this to determine whether certain
features are supported. Currently, the possible values are 2 (2.0
protocol), 3 (3.0 protocol), or zero (connection bad). This will not
change after connection startup is complete, but it could
theoretically change during a connection reset. The 3.0 protocol will
normally be used when communicating with PostgreSQL 7.4 or later
servers; pre-7.4 servers support only protocol 2.0. (Protocol 1.0 is
obsolete and not supported by libpq.)

=item $dbc->serverVersion

Returns an integer representing the backend version.

Applications might use this to determine the version of the database
server they are connected to. The number is formed by converting the
major, minor, and revision numbers into two-decimal-digit numbers and
appending them together. For example, version 8.1.5 will be returned
as 80105, and version 8.2 will be returned as 80200 (leading zeroes
are not shown). Zero is returned if the connection is bad.

=item $dbc->errorMessage

Returns the error message most recently generated by an operation on
the connection.

Nearly all libpq functions will set a message for C<errorMessage> if
they fail. Note that by libpq convention, a nonempty C<errorMessage>
result can be multiple lines.

=item $dbc->socket

Obtains the file descriptor number of the connection socket to the
server. A valid descriptor will be greater than or equal to 0; a
result of -1 indicates that no server connection is currently
open. (This will not change during normal operation, but could change
during connection setup or reset.)

=item $dbc->backendPID

Returns the process ID (PID) of the backend server process handling
this connection.

The backend PID is useful for debugging purposes and for comparison to
C<NOTIFY> messages (which include the PID of the notifying backend
process). Note that the PID belongs to a process executing on the
database server host, not the local host!

=item $dbc->connectionNeedsPassword

Returns true if the connection authentication method required a
password, but none was available. Returns false if not.

This function can be applied after a failed connection attempt to
decide whether to prompt the user for a password.

=item $dbc->connectionUsedPassword

Returns true if the connection authentication method used a
password. Returns false if not.

This function can be applied after either a failed or successful
connection attempt to detect whether the server demanded a password.

=item $dbc->finish

Closes the connection to the server and frees the underlaying libpq
PGconn data structure. This method is automatically called by C<DESTROY>.

=item $dbc->reset

This function will close the connection to the server and attempt to
reestablish a new connection to the same server, using all the same
parameters previously used. This might be useful for error recovery if
a working connection is lost.

=item $dbc->resetStart

=item $dbc->resetPoll

Reset the communication channel to the server, in a nonblocking manner.

These functions will close the connection to the server and attempt to
reestablish a new connection to the same server, using all the same
parameters previously used. This can be useful for error recovery if a
working connection is lost. They differ from C<reset> (above) in that
they act in a nonblocking manner. These functions suffer from the same
restrictions as C<start> and C<connectPoll>.

To initiate a connection reset, call C<resetStart>. If it returns 0,
the reset has failed. If it returns 1, poll the reset using
C<resetPoll> in exactly the same way as you would create the
connection using C<connectPoll>.

=item $dbc->trace

# FIXME

=item $dbc->untrace

# FIXME

=item $dbc->execQuery

Submits a command to the server and waits for the result.

Returns a Pg::PQ::Result object or undef. A valid object will
generally be returned except in out-of-memory conditions or serious
errors such as inability to send the command to the server. If
C<undef> is returned, it should be treated like a C<PGRES_FATAL_ERROR>
result. Use C<errorMessage> to get more information about such errors.

It is allowed to include multiple SQL commands (separated by
semicolons) in the command string. Multiple queries sent in a single
C<execQuery> call are processed in a single transaction, unless there
are explicit C<BEGIN>/C<COMMIT> commands included in the query string
to divide it into multiple transactions. Note however that the
returned Pg::PQ::Result object describes only the result of the
last command executed from the string. Should one of the commands
fail, processing of the string stops with it and the returned
Pg::PQ::Result object describes the error condition.

=item $res = $dbc->prepare($name => $query)

Submits a request to create a prepared statement with the given
parameters, and waits for completion.

C<prepare> creates a prepared statement for later execution with
C<execQueryPrepared>. This feature allows commands that will be used
repeatedly to be parsed and planned just once, rather than each time
they are executed. C<prepare> is supported only in protocol 3.0 and
later connections; it will fail when using protocol 2.0.

The function creates a prepared statement named C<$name> from the
C<$query> string, which must contain a single SQL command. C<$name>
can be "" to create an unnamed statement, in which case any
pre-existing unnamed statement is automatically replaced; otherwise it
is an error if the statement name is already defined in the current
session. If any parameters are used, they are referred to in the query
as $1, $2, etc. (see C<describePrepared> for a means to find out what
data types were inferred).

As with C<execQuery>, the result is normally a Pg::PQ::Result object
whose contents indicate server-side success or failure. An undefined
result indicates out-of-memory or inability to send the command at
all. Use C<errorMessage> to get more information about such errors.

Prepared statements for use with C<execQueryPrepared> can also be
created by executing SQL C<PREPARE> statements. Also, although there
is no libpq function for deleting a prepared statement, the SQL
C<DEALLOCATE> statement can be used for that purpose.

=item $res = $dbc->execQueryPrepared($name => @args)

Sends a request to execute a prepared statement with given parameters,
and waits for the result.

C<execQueryPrepared> is like C<exec>, but the command to be executed
is specified by naming a previously-prepared statement, instead of
giving a query string. This feature allows commands that will be used
repeatedly to be parsed and planned just once, rather than each time
they are executed. The statement must have been prepared previously in
the current session. C<execQueryPrepared> is supported only in
protocol 3.0 and later connections; it will fail when using protocol
2.0.

The parameters are identical to C<execQueryParams>, except that the
name of a prepared statement is given instead of a query string.

=item $res = $dbc->describePrepared($name)

Submits a request to obtain information about the specified prepared
statement, and waits for completion.

C<describePrepared> allows an application to obtain information about
a previously prepared statement. It is supported only in protocol 3.0
and later connections; it will fail when using protocol 2.0.

C<$name> can be "" to reference the unnamed statement, otherwise it
must be the name of an existing prepared statement. On success, a
Pg::PQ::Result object with status C<PGRES_COMMAND_OK> is returned. The
functions C<nParams> and C<paramType> can be applied to this
Pg::PQ::Result object to obtain information about the parameters of
the prepared statement, and the methods C<nFields>, C<fName>,
C<fType>, etc provide information about the result columns (if any) of
the statement.

=item $dbc->describePortal($portalName)

Submits a request to obtain information about the specified portal,
and waits for completion.

C<describePortal> allows an application to obtain information about a
previously created portal (libpq does not provide any direct access to
portals, but you can use this function to inspect the properties of a
cursor created with a DECLARE CURSOR SQL command). C<describePortal>
is supported only in protocol 3.0 and later connections; it will fail
when using protocol 2.0.

C<$name> can be "" to reference the unnamed portal, otherwise it must
be the name of an existing portal. On success, a Pg::PQ::Result object
with status C<PGRES_COMMAND_OK> is returned. Its methods C<nFields>,
C<fName>, C<fType>, etc can be called to obtain information about the
result columns (if any) of the portal.

=item $dbc->sendQuery

=item $dbc->sendQueryPrepared

=item $dbc->result

=item $dbc->consumeInput

=item $dbc->busy

=item $dbc->nonBlocking

=item $dbc->flush



=item $dbc->getCancel



=item $dbc->notifies

=item $dbc->makeEmptyResult

=item $dbc->escapeString

=back

=head2 Constants

=head1 SEE ALSO

Most of the time you would prefer to use L<DBD::Pg> through L<DBI> (the
standard Perl database access module) to PostgreSQL databases.

L<AnyEvent::Pg> integrates Pg::PQ under the L<AnyEvent> framework.

The original PostgreSQL documentation available from
L<http://www.postgresql.org/docs/>. Note that this module is a thin
layer on top of libpq, and probably the documentation corresponding to
the version of libpq installed on your machine would actually be more
accurate in some aspects than that included here.

=head1 AUTHOR

Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Qindel FormaciE<oacute>n y Servicios S.L.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

The documentation of this module is based on the original libpq
documentation that has the following copyright:

Copyright (C) 1996-2011 PostgreSQL Global Development Group.

=cut
