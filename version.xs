#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "util.h"

/* --------------------------------------------------
 * $Revision: 2.5 $
 * --------------------------------------------------*/

typedef     SV *version;

MODULE = version	PACKAGE = version

PROTOTYPES: DISABLE
VERSIONCHECK: DISABLE

BOOT:
	/* register the overloading (type 'A') magic */
	PL_amagic_generation++;
	newXS("version::()", XS_version_noop, file);
	newXS("version::(\"\"", XS_version_stringify, file);
	newXS("version::(0+", XS_version_numify, file);
	newXS("version::(cmp", XS_version_vcmp, file);
	newXS("version::(<=>", XS_version_vcmp, file);
	newXS("version::(bool", XS_version_boolean, file);
	newXS("version::(nomethod", XS_version_noop, file);
	newXS("UNIVERSAL::VERSION", XS_version_VERSION, file);

version
new(class,...)
    char *class
PPCODE:
{
    SV *vs = ST(1);
    SV *rv;
    if (items == 3 )
    {
	char *version = savepvn(SvPVX(ST(2)),SvCUR(ST(2)));
	vs = newSVpvf("v%s",version);
    }

    rv = new_version(vs);
    if ( strcmp(class,"version") != 0 ) /* inherited new() */
	sv_bless(rv, gv_stashpv(class,TRUE));

    PUSHs(rv);
}

void
stringify (lobj,...)
    version		lobj
PPCODE:
{
    PUSHs(vstringify(lobj));
}

void
numify (lobj,...)
    version		lobj
PPCODE:
{
    PUSHs(vnumify(lobj));
}

void
vcmp (lobj,...)
    version		lobj
PPCODE:
{
    SV	*rs;
    SV	*rvs;
    SV * robj = ST(1);
    IV	 swap = (IV)SvIV(ST(2));

    if ( ! sv_derived_from(robj, "version") )
    {
	robj = new_version(robj);
    }
    rvs = SvRV(robj);

    if ( swap )
    {
        rs = newSViv(vcmp(rvs,lobj));
    }
    else
    {
        rs = newSViv(vcmp(lobj,rvs));
    }

    PUSHs(sv_2mortal(rs));
}

void
boolean(lobj,...)
    version		lobj
PPCODE:
{
    SV	*rs;
    rs = newSViv( vcmp(lobj,new_version(newSVpvn("0",1))) );
    PUSHs(sv_2mortal(rs));
}

void
noop(lobj,...)
    version		lobj
CODE:
{
    Perl_croak(aTHX_ "operation not supported with version object");
}

void
is_alpha(lobj)
    version		lobj	
PPCODE:
{
    I32 len = av_len((AV *)lobj);
    I32 digit = SvIVX(*av_fetch((AV *)lobj, len, 0));
    if ( digit < 0 )
	XSRETURN_YES;
    else
	XSRETURN_NO;
}

void
VERSION(sv,...)
    SV *sv
PPCODE:
{
    HV *pkg;
    GV **gvp;
    GV *gv;
    char *undef;

    if (SvROK(sv)) {
        sv = (SV*)SvRV(sv);
        if (!SvOBJECT(sv))
            Perl_croak(aTHX_ "Cannot find version of an unblessed reference");
        pkg = SvSTASH(sv);
    }
    else {
        pkg = gv_stashsv(sv, FALSE);
    }

    gvp = pkg ? (GV**)hv_fetch(pkg,"VERSION",7,FALSE) : Null(GV**);

    if (gvp && isGV(gv = *gvp) && SvOK(sv = GvSV(gv))) {
        SV *nsv = sv_newmortal();
        sv_setsv(nsv, sv);
        sv = nsv;
        undef = Nullch;
    }
    else {
        sv = (SV*)&PL_sv_undef;
        undef = "(undef)";
    }

    if (items > 1) {
	SV *req = ST(1);
	STRLEN len;

	if (undef) {
	     if (pkg)
		  Perl_croak(aTHX_ "%s does not define $%s::VERSION--version check failed",
			     HvNAME(pkg), HvNAME(pkg));
	     else {
		  char *str = SvPVx(ST(0), len);

		  Perl_croak(aTHX_ "%s defines neither package nor VERSION--version check failed", str);
	     }
	}
	if ( !sv_derived_from(sv, "version"))
	    upg_version(sv);

	if ( !sv_derived_from(req, "version"))
	    req = new_version(req); /* req is R/O so we have to use new */

	if ( vcmp( req, sv ) > 0 )
	    Perl_croak(aTHX_ "%s version %_ required--this is only version %_",
		       HvNAME(pkg), req, sv);
    }

    PUSHs(sv);

    XSRETURN(1);
}
