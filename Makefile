# Created by: Robert Drake <rdrake@cpan.org>
# this should be renamed to Makefile before running
# $FreeBSD$
# $NetBSD: $


PORTNAME=		App-Tel
PORTVERSION=	0.201004
CATEGORIES=		net-mgmt
PKGNAMEPREFIX=	p5-

MASTER_SITES=	CPAN

USES=			perl5
USE_PERL5=		configure

MAINTAINER=		rdrake@cpan.org
COMMENT=		tel script - manage telnet or ssh for routers/switches and other devices

BUILD_DEPENDS=	p5-Test-Most>=0.31:${PORTSDIR}/devel/p5-Test-Most
RUN_DEPENDS:=	${BUILD_DEPENDS}
RUN_DEPENDS:=	p5-Hash-Merge-Simple>=0:${PORTSDIR}/devel/p5-Hash-Merge-Simple
RUN_DEPENDS:=	p5-Expect>=0:${PORTSDIR}/lang/p5-Expect
RUN_DEPENDS:=	p5-IO-Stty>=0:${PORTSDIR}/devel/p5-IO-Stty

.include <bsd.port.mk>
