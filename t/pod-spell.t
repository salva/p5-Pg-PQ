#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

eval "use Test::Spelling";
plan skip_all => "Test::Spelling required for testing POD spelling" if $@;

my @ignore = (qw(Qindel Servicios GCCAPI OID OIDs OpenSSL PGconn
                 PGresult PQconnectPoll PQconnectStart PQconnectdb
                 PQexec PQexecParams PQexecPrepared PQgetResult
                 PQsendQuery PQsendQueryParams PostgreSQL QVD
                 QindelGroup SQLSTATE SSPI TCP TODO UNLISTEN VDI
                 dbname downcased gssapi gsslib hostaddr inmediately
                 keepalive keepalives libpq pgres pqerrors sqlstate
                 sslcert sslcrl sslkey sslmode str CRL GSS geqo hoc
                 krbsrvname pqtrans sslrootcert traceback copyres
                 localizable retransmitted),
              "Fandi\xf1o", "Formaci\xf3n");

local $ENV{LC_ALL} = 'C';
add_stopwords(@ignore);
all_pod_files_spelling_ok();
