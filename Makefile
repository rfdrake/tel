# Created by: Robert Drake <rdrake@cpan.org>
# this file needs to be renamed to "Makefile" in order to build the package,
# otherwise you'll get an error saying
# make: don't know how to make master-sites-DEFAULT. Stop

  DISTNAME=               myscripts-1.0

# need to check these for openbsd
#PORTNAME=		App-Tel
#PORTVERSION=	0.201004
CATEGORIES=		net-mgmt
#PKGNAMEPREFIX=	p5-

# these too
#MASTER_SITES=	CPAN

#USES=			perl5
#USE_PERL5=		configure

MAINTAINER=		rdrake@cpan.org
COMMENT=		tel script - manage telnet or ssh for routers/switches and other devices


.include <bsd.port.mk>
