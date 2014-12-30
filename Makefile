# Created by: Robert Drake <rdrake@cpan.org>
# $OpenBSD: $

COMMENT=		tel script - manage telnet or ssh for routers/switches and other devices
MAINTAINER=		rdrake@cpan.org
DISTNAME=		App-Tel-0.201004
CATEGORIES=		net
MODULES=		cpan

PERMIT_PACKAGE_CDROM=	Yes
CPAN_AUTHOR=	RDRAKE


BUILD_DEPENDS=			devel/p5-Test-Most
RUN_DEPENDS:=			${BUILD_DEPENDS}

RUN_DEPENDS:=			devel/p5-Expect \
# Hash-Merge-Simple and IO-Stty aren't in ports.. not sure what to do about
# that except I could make ports for them, but that's a huge pain..
#						devel/p5-IO-Stty \
                        devel/p5-Hash-Merge-Simple



.include <bsd.port.mk>
