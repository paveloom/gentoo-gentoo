# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit tree-sitter-grammar

DESCRIPTION="Markdown grammar for Tree-sitter"
HOMEPAGE="https://github.com/tree-sitter-grammars/tree-sitter-markdown"
SRC_URI="https://github.com/tree-sitter-grammars/tree-sitter-markdown/archive/v${PV}.tar.gz -> ${P}.tar.gz"
S=${WORKDIR}/${P}/${PN}

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~ppc ~ppc64 ~riscv ~x86"

src_prepare() {
	# Trick `tree-sitter-grammar.eclass` to make it use `make`
	ln -s ../pyproject.toml . || die

	eapply --directory=.. \
		"${FILESDIR}/${PN}-0.5.3-r1-install-queries-under-the-unprefixed-name.patch"

	tree-sitter-grammar_src_prepare
}
