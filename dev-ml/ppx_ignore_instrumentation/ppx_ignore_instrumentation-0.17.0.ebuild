# Copyright 2022-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit dune

DESCRIPTION="Ignore Jane Street specific instrumentation extensions"
HOMEPAGE="https://github.com/janestreet/ppx_ignore_instrumentation"
SRC_URI="https://github.com/janestreet/${PN}/archive/refs/tags/v${PV}.tar.gz
	-> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0/$(ver_cut 1-2)"
KEYWORDS="~amd64 ~arm64 ~ppc ~ppc64 ~riscv"
IUSE="+ocamlopt"

RDEPEND=">=dev-ml/ppxlib-0.32.1:=[ocamlopt?]"
DEPEND="${RDEPEND}"
BDEPEND=">=dev-ml/dune-3.11"
