#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_sv_2pv_nolen_GLOBAL
#include "ppport.h"
#include "vutil.h"

/* --------------------------------------------------
 * $Revision: 2.5 $
 * --------------------------------------------------*/

typedef     SV *version_vxs;

#include "vxs.inc"

struct xsub_details {
    const char *name;
    XSUBADDR_t xsub;
    const char *proto; /* ignored */
};

static const struct xsub_details details[] = {
#define VXS_XSUB_DETAILS
#include "vxs.inc"
#undef VXS_XSUB_DETAILS
};

MODULE = version::vxs PACKAGE = version::vxs

PROTOTYPES: DISABLE
VERSIONCHECK: DISABLE

BOOT:
    {
#if (PERL_REVISION == 5 && PERL_VERSION < 9)
	char* file = __FILE__;
#else
	const char* file = __FILE__;
#endif
	const struct xsub_details *xsub = details;
	const struct xsub_details *end
		= details + sizeof(details) / sizeof(details[0]);
        /* register the overloading (type 'A') magic */
        PL_amagic_generation++;
	do {
	    newXS(xsub->name, xsub->xsub, file);
	} while (++xsub < end);
    }
