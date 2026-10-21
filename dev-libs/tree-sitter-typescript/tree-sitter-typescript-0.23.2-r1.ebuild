# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit tree-sitter-grammar

DESCRIPTION="TypeScript grammar for Tree-sitter"
HOMEPAGE="https://github.com/tree-sitter/tree-sitter-typescript"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

PATCHES=(
	"${FILESDIR}/${PN}-0.23.2-r1-install-queries.patch"
)

src_prepare() {
	# Let the `_get_tsg_abi_ver` function extract the ABI version
	mkdir src || die
	ln -rs typescript/src/parser.c src/ || die

	tree-sitter-grammar_src_prepare
}
