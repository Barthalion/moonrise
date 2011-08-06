# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/pearpc/pearpc-0.4.ebuild,v 1.13 2009/09/06 21:18:20 robbat2 Exp $

inherit eutils flag-o-matic linux-mod

DESCRIPTION="PowerPC Architecture Emulator"
HOMEPAGE="http://pearpc.sourceforge.net/"
SRC_URI="mirror://sourceforge/pearpc/${P}.tar.bz2
   http://pearpc.sf.net/createdisk.py"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE="debug jit X sdl"

RDEPEND="sys-apps/net-tools
   sdl? ( >=media-libs/libsdl-1.2.0 )
   X? ( x11-libs/libX11 )
   net-firewall/iptables
   net-misc/bridge-utils"
DEPEND="${RDEPEND}
   sys-devel/flex
   sys-devel/bison
   x86? ( dev-lang/nasm )
   jit? ( dev-lang/nasm )"

src_unpack() {
   unpack ${A}
   cd "${S}"

   #epatch "${FILESDIR}/${P}-configure.patch"
}

pkg_setup() {
   linux-mod_pkg_setup
   if ! linux_chkconfig_present TUN; then
      die "You must have TUN/TAP enabled in your kernel."
   fi
}

src_compile() {
   local myconf

   use jit && myconf="${myconf} --enable-cpu=jitc_x86"
   if use sdl; then
      myconf="${myconf} --enable-ui=sdl"
   elif use X; then
      myconf="${myconf} --enable-ui=x11"
   else
      die "You must set at least one of these flags: X, sdl"
   fi

   econf \
      $(use_enable debug) \
      ${myconf} \
      || die "econf failed"
   emake || die "emake failed"
   sed -i -e "s:video.x:/usr/share/${P}/video.x:g" ppccfg.example
}

src_install() {
   dobin src/ppc
   dodoc ChangeLog AUTHORS README TODO ppccfg.example

   insinto /usr/share/${P}
   doins scripts/ifppc_{down,up}{,.setuid} video.x "${FILESDIR}"/settings
   fperms u+s,a+x /usr/share/${P}/ifppc_{up,down}.setuid

   insinto /usr/share/${P}/scripts
   doins "${DISTDIR}"/createdisk.py
}

pkg_postinst() {
   elog "You will need to update your configuration files to point"
   elog "to the new location of video.x, which is now"
   elog "/usr/share/${P}/video.x"
   elog ""
   elog "To create disk images for PearPC, you can use the Python"
   elog "script located at: /usr/share/${P}/scripts/createdisk.py"
   elog "Usage: createdisk.py <image name> <image size>"
   elog ""
   elog "Also, be sure to check ppccfg.example in /usr/share/doc/${P}/"
   elog "for new configuration options."
}
