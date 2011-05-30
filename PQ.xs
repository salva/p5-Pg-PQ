#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#ifdef _
#undef _
#endif

#include <libpq-fe.h>

SV *
make_constant(char *name, STRLEN l, U32 value) {
    SV *sv = newSV(0);
    SvUPGRADE(sv, SVt_PVIV);
    sv_setpvn(sv, name, l);
    SvIOK_on(sv);
    SvIsUV_on(sv);
    SvUV_set(sv, value);
    SvREADONLY_on(sv);
    newCONSTSUB(gv_stashpv("Pg::PQ::Constant", 1), name, sv);
    return sv;
}

#include "enums.c"


MODULE = Pg::PQ		PACKAGE = Pg::PQ		PREFIX=PQ

PROTOTYPES: DISABLE

BOOT:
    init_constants();



PGconn *PQconnectdb(const char *conninfo);

PGconn *PQconnectStart(char *conninfo)


MODULE = Pg::PQ		PACKAGE = Pg::PQ::Conn          PREFIX=PQ

PostgresPollingStatusType PQconnectPoll(PGconn *conn)

char *PQdb(PGconn *conn)

char *PQuser(PGconn *conn)

char *PQpass(PGconn *conn)

char *PQhost(PGconn *conn)

char *PQport(PGconn *conn)

char *PQoptions( PGconn *conn)

ConnStatusType PQstatus(PGconn *conn)

PGTransactionStatusType PQtransactionStatus(PGconn *conn)

const char *PQparameterStatus(PGconn *conn, char *paramName)

int PQprotocolVersion(PGconn *conn)

int PQserverVersion(PGconn *conn)

char *PQerrorMessage(PGconn *conn)

int PQsocket(PGconn *conn)

int PQbackendPID(PGconn *conn)

int PQconnectionNeedsPassword(PGconn *conn)

int PQconnectionUsedPassword(PGconn *conn)

# SSL *PQgetssl(PGconn *conn)


