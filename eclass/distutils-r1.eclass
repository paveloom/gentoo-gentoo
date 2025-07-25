# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: distutils-r1.eclass
# @MAINTAINER:
# Python team <python@gentoo.org>
# @AUTHOR:
# Author: Michał Górny <mgorny@gentoo.org>
# Based on the work of: Krzysztof Pawlik <nelchael@gentoo.org>
# @SUPPORTED_EAPIS: 8
# @PROVIDES: python-r1 python-single-r1
# @BLURB: A simple eclass to build Python packages using distutils.
# @DESCRIPTION:
# A simple eclass providing functions to build Python packages using
# the distutils build system. It exports phase functions for all
# the src_* phases. Each of the phases runs two pseudo-phases:
# python_..._all() (e.g. python_prepare_all()) once in ${S}, then
# python_...() (e.g. python_prepare()) for each implementation
# (see: python_foreach_impl() in python-r1).
#
# In distutils-r1_src_prepare(), the 'all' function is run before
# per-implementation ones (because it creates the implementations),
# per-implementation functions are run in a random order.
#
# In remaining phase functions, the per-implementation functions are run
# before the 'all' one, and they are ordered from the least to the most
# preferred implementation (so that 'better' files overwrite 'worse'
# ones).
#
# If the ebuild doesn't specify a particular pseudo-phase function,
# the default one will be used (distutils-r1_...). Defaults are provided
# for all per-implementation pseudo-phases, python_prepare_all()
# and python_install_all(); whenever writing your own pseudo-phase
# functions, you should consider calling the defaults (and especially
# distutils-r1_python_prepare_all).
#
# Please note that distutils-r1 sets RDEPEND and BDEPEND (or DEPEND
# in earlier EAPIs) unconditionally for you.
#
# Also, please note that distutils-r1 will always inherit python-r1
# as well. Thus, all the variables defined and documented there are
# relevant to the packages using distutils-r1.
#
# For more information, please see the Python Guide:
# https://projects.gentoo.org/python/guide/

# @ECLASS_VARIABLE: DISTUTILS_EXT
# @PRE_INHERIT
# @DEFAULT_UNSET
# @DESCRIPTION:
# Set this variable to a non-null value if the package (possibly
# optionally) builds Python extensions (loadable modules written in C,
# Cython, Rust, etc.).
#
# When enabled, the eclass:
#
# - adds PYTHON_DEPS to DEPEND (for cross-compilation support), unless
#   DISTUTILS_OPTIONAL is used
#
# - adds `debug` flag to IUSE that controls assertions (i.e. -DNDEBUG)
#
# - calls `build_ext` command if setuptools build backend is used
#   and there is potential benefit from parallel builds

# @ECLASS_VARIABLE: DISTUTILS_OPTIONAL
# @DEFAULT_UNSET
# @DESCRIPTION:
# If set to a non-null value, distutils part in the ebuild will
# be considered optional. No dependencies will be added and no phase
# functions will be exported.
#
# If you enable DISTUTILS_OPTIONAL, you have to set proper dependencies
# for your package (using ${PYTHON_DEPS}) and to either call
# distutils-r1 default phase functions or call the build system
# manually.
#
# Note that if DISTUTILS_SINGLE_IMPL is used, python-single-r1 exports
# pkg_setup() function.  In that case, it is necessary to redefine
# pkg_setup() to call python-single-r1_pkg_setup over correct
# conditions.

# @ECLASS_VARIABLE: DISTUTILS_SINGLE_IMPL
# @DEFAULT_UNSET
# @DESCRIPTION:
# If set to a non-null value, the ebuild will support setting a single
# Python implementation only. It will effectively replace the python-r1
# eclass inherit with python-single-r1.
#
# Note that inheriting python-single-r1 will cause pkg_setup()
# to be exported. It must be run in order for the eclass functions
# to function properly.

# @ECLASS_VARIABLE: DISTUTILS_USE_PEP517
# @PRE_INHERIT
# @REQUIRED
# @DESCRIPTION:
# Specifies the PEP517 build system used for the package.  Currently,
# the following values are supported:
#
# - flit - flit-core backend
#
# - flit_scm - flit_scm backend
#
# - hatchling - hatchling backend (from hatch)
#
# - jupyter - jupyter_packaging backend
#
# - maturin - maturin backend
#
# - meson-python - meson-python (mesonpy) backend
#
# - no - no PEP517 build system (see below)
#
# - pbr - pbr backend
#
# - pdm-backend - pdm.backend backend
#
# - poetry - poetry-core backend
#
# - scikit-build-core - scikit-build-core backend
#
# - setuptools - distutils or setuptools (incl. legacy mode)
#
# - sip - sipbuild backend
#
# - standalone - standalone/local build systems
#
# - uv-build - uv-build backend (using dev-python/uv)
#
# The variable needs to be set before the inherit line.  If another
# value than "standalone" and "no" is used, The eclass adds appropriate
# build-time dependencies, verifies the value and calls the appropriate
# modern entry point for the backend.  With DISTUTILS_UPSTREAM_PEP517,
# this variable can be used to override the upstream build backend.
#
# The value of "standalone" indicates that upstream is using a custom,
# local build backend.  In this mode, the eclass does not add any
# dependencies, disables build backend verification and uses the exact
# entry point listed in pyproject.toml.
#
# The special value "no" indicates that the package has no build system.
# It causes the eclass not to include any build system dependencies
# and to disable default python_compile() and python_install()
# implementations.  Baseline Python deps and phase functions will still
# be set (depending on the value of DISTUTILS_OPTIONAL).  Most of
# the other eclass functions will work.  Testing venv will be provided
# in ${BUILD_DIR}/install after python_compile(), and if any (other)
# files are found in ${BUILD_DIR}/install after python_install(), they
# will be merged into ${D}.

# @ECLASS_VARIABLE: DISTUTILS_UPSTREAM_PEP517
# @DEFAULT_UNSET
# @DESCRIPTION:
# Specifies the PEP517 build backend used upstream.  It is used
# by the eclass to verify the correctness of DISTUTILS_USE_PEP517,
# and defaults to ${DISTUTILS_USE_PEP517}.  However, it can be
# overriden to workaround the eclass check, when it is desirable
# to build the wheel using other backend than the one used upstream.
#
# When using it, ideally it should list the build backend actually used
# upstream, so the eclass will throw an error if that backend changes
# (and therefore overrides may need to change as well).  As a special
# case, setting it to "standalone" disables the check entirely (while
# still forcing the backend, unlike DISTUTILS_USE_PEP517=standalone).
#
# Please note that even in packages using PEP621 metadata, there can
# be subtle differences between the behavior of different PEP517 build
# backends, for example regarding finding package files.  When using
# this option, please make sure that the package is installed correctly.

# @ECLASS_VARIABLE: DISTUTILS_DEPS
# @OUTPUT_VARIABLE
# @DESCRIPTION:
# This is an eclass-generated build-time dependency string for the build
# system packages.  This string is automatically appended to BDEPEND
# unless DISTUTILS_OPTIONAL is used.
#
# Example use:
# @CODE
# DISTUTILS_OPTIONAL=1
# # ...
# RDEPEND="${PYTHON_DEPS}"
# BDEPEND="
#     ${PYTHON_DEPS}
#     ${DISTUTILS_DEPS}"
# @CODE

# @ECLASS_VARIABLE: DISTUTILS_ALLOW_WHEEL_REUSE
# @USER_VARIABLE
# @DESCRIPTION:
# If set to a non-empty value, the eclass is allowed to reuse a wheel
# that was built for a prior Python implementation, provided that it is
# compatible with the current one, rather than building a new one.
#
# This is an optimization that can avoid the overhead of calling into
# the build system in pure Python packages and packages using the stable
# Python ABI.
: "${DISTUTILS_ALLOW_WHEEL_REUSE=1}"

# @ECLASS_VARIABLE: BUILD_DIR
# @OUTPUT_VARIABLE
# @DEFAULT_UNSET
# @DESCRIPTION:
# The current build directory. In global scope, it is supposed to
# contain an initial build directory; if unset, it defaults to ${S}.
#
# When running in multi-impl mode, the BUILD_DIR variable is set
# by python-r1.eclass.  Otherwise, it is set by distutils-r1.eclass
# for consistency.
#
# Example value:
# @CODE
# ${WORKDIR}/foo-1.3-python3_12
# @CODE

if [[ -z ${_DISTUTILS_R1_ECLASS} ]]; then
_DISTUTILS_R1_ECLASS=1

case ${EAPI} in
	8) ;;
	*) die "${ECLASS}: EAPI ${EAPI:-0} not supported" ;;
esac

inherit flag-o-matic
inherit multibuild multilib multiprocessing ninja-utils toolchain-funcs

if [[ ${DISTUTILS_USE_PEP517} == meson-python ]]; then
	inherit meson
fi

if [[ ! ${DISTUTILS_SINGLE_IMPL} ]]; then
	inherit python-r1
else
	inherit python-single-r1
fi

_distutils_set_globals() {
	local rdep bdep
	bdep='
		>=dev-python/gpep517-16[${PYTHON_USEDEP}]
	'
	case ${DISTUTILS_USE_PEP517} in
		flit)
			bdep+='
				>=dev-python/flit-core-3.11.0[${PYTHON_USEDEP}]
			'
			;;
		flit_scm)
			bdep+='
				>=dev-python/flit-core-3.11.0[${PYTHON_USEDEP}]
				>=dev-python/flit-scm-1.7.0[${PYTHON_USEDEP}]
			'
			;;
		hatchling)
			bdep+='
				>=dev-python/hatchling-1.27.0[${PYTHON_USEDEP}]
			'
			;;
		jupyter)
			bdep+='
				>=dev-python/jupyter-packaging-0.12.3[${PYTHON_USEDEP}]
			'
			;;
		maturin)
			bdep+='
				>=dev-util/maturin-1.8.2[${PYTHON_USEDEP}]
			'
			;;
		no)
			# undo the generic deps added above
			bdep=
			;;
		meson-python)
			bdep+='
				>=dev-python/meson-python-0.17.1[${PYTHON_USEDEP}]
			'
			;;
		pbr)
			bdep+='
				>=dev-python/pbr-6.1.1[${PYTHON_USEDEP}]
			'
			;;
		pdm-backend)
			bdep+='
				>=dev-python/pdm-backend-2.4.3[${PYTHON_USEDEP}]
			'
			;;
		poetry)
			bdep+='
				>=dev-python/poetry-core-2.1.1[${PYTHON_USEDEP}]
			'
			;;
		scikit-build-core)
			bdep+='
				>=dev-python/scikit-build-core-0.10.7[${PYTHON_USEDEP}]
			'
			;;
		setuptools)
			bdep+='
				>=dev-python/setuptools-78.1.0[${PYTHON_USEDEP}]
			'
			;;
		sip)
			bdep+='
				>=dev-python/sip-6.10.0[${PYTHON_USEDEP}]
			'
			;;
		standalone)
			;;
		uv-build)
			bdep+='
				dev-python/uv-build[${PYTHON_USEDEP}]
			'
			;;
		*)
			die "Unknown DISTUTILS_USE_PEP517=${DISTUTILS_USE_PEP517}"
			;;
	esac

	if [[ ! ${DISTUTILS_SINGLE_IMPL} ]]; then
		bdep=${bdep//\$\{PYTHON_USEDEP\}/${PYTHON_USEDEP}}
		rdep=${rdep//\$\{PYTHON_USEDEP\}/${PYTHON_USEDEP}}
	else
		[[ -n ${bdep} ]] && bdep="$(python_gen_cond_dep "${bdep}")"
		[[ -n ${rdep} ]] && rdep="$(python_gen_cond_dep "${rdep}")"
	fi

	if [[ ${DISTUTILS_DEPS+1} ]]; then
		if [[ ${DISTUTILS_DEPS} != "${bdep}" ]]; then
			eerror "DISTUTILS_DEPS have changed between inherits!"
			eerror "Before: ${DISTUTILS_DEPS}"
			eerror "Now   : ${bdep}"
			die "DISTUTILS_DEPS integrity check failed"
		fi
	else
		DISTUTILS_DEPS=${bdep}
		readonly DISTUTILS_DEPS
	fi

	if [[ ! ${DISTUTILS_OPTIONAL} ]]; then
		RDEPEND="${PYTHON_DEPS} ${rdep}"
		BDEPEND="${PYTHON_DEPS} ${bdep}"
		REQUIRED_USE=${PYTHON_REQUIRED_USE}

		if [[ ${DISTUTILS_EXT} ]]; then
			DEPEND="${PYTHON_DEPS}"
		fi
	fi

	if [[ ${DISTUTILS_EXT} ]]; then
		IUSE="debug"
	fi
}
_distutils_set_globals
unset -f _distutils_set_globals

# @ECLASS_VARIABLE: DISTUTILS_ALL_SUBPHASE_IMPLS
# @DEFAULT_UNSET
# @DESCRIPTION:
# An array of patterns specifying which implementations can be used
# for *_all() sub-phase functions. If undefined, defaults to '*'
# (allowing any implementation). If multiple values are specified,
# implementations matching any of the patterns will be accepted.
#
# For the pattern syntax, please see _python_impl_matches
# in python-utils-r1.eclass.
#
# If the restriction needs to apply conditionally to a USE flag,
# the variable should be set conditionally as well (e.g. in an early
# phase function or other convenient location).
#
# Please remember to add a matching || block to REQUIRED_USE,
# to ensure that at least one implementation matching the patterns will
# be enabled.
#
# Example:
# @CODE
# REQUIRED_USE="doc? ( || ( $(python_gen_useflags 'python2*') ) )"
#
# pkg_setup() {
#     use doc && DISTUTILS_ALL_SUBPHASE_IMPLS=( 'python2*' )
# }
# @CODE

# @ECLASS_VARIABLE: DISTUTILS_ARGS
# @DEFAULT_UNSET
# @DESCRIPTION:
# An array containing options to be passed to the build system.
# Supported by a subset of build systems used by the eclass.
#
# For maturin, the arguments will be passed as `maturin build`
# arguments.
#
# For meson-python, the arguments will be passed as `meson setup`
# arguments.
#
# For scikit-build-core, the arguments will be passed as `cmake`
# options (e.g. `-DFOO=BAR` form should be used).
#
# For setuptools, the arguments will be passed as first parameters
# to setup.py invocations (via esetup.py), as well as to the PEP517
# backend.  For future compatibility, only global options should be used
# and specifying commands should be avoided.
#
# For sip, the options are passed to the PEP517 backend in a form
# resembling sip-build calls.  Options taking arguments need to
# be specified in the "--key=value" form, while flag options as "--key".
# If an option takes multiple arguments, it can be specified multiple
# times, same as for sip-build.
#
# Example:
# @CODE
# python_configure_all() {
# 	DISTUTILS_ARGS=( --enable-my-hidden-option )
# }
# @CODE

# @FUNCTION: distutils_enable_sphinx
# @USAGE: <subdir> [--no-autodoc | <plugin-pkgs>...]
# @DESCRIPTION:
# Set up IUSE, BDEPEND, python_check_deps() and python_compile_all() for
# building HTML docs via dev-python/sphinx.  python_compile_all() will
# append to HTML_DOCS if docs are enabled.
#
# This helper is meant for the most common case, that is a single Sphinx
# subdirectory with standard layout, building and installing HTML docs
# behind USE=doc.  It assumes it's the only consumer of the three
# aforementioned functions.  If you need to use a custom implementation,
# you can't use it.
#
# If your package uses additional Sphinx plugins, they should be passed
# (without PYTHON_USEDEP) as <plugin-pkgs>.  The function will take care
# of setting appropriate any-of dep and python_check_deps().
#
# If no plugin packages are specified, the eclass will still utilize
# any-r1 API to support autodoc (documenting source code).
# If the package uses neither autodoc nor additional plugins, you should
# pass --no-autodoc to disable this API and simplify the resulting code.
#
# This function must be called in global scope.  Take care not to
# overwrite the variables set by it.  If you need to extend
# python_compile_all(), you can call the original implementation
# as sphinx_compile_all.
distutils_enable_sphinx() {
	debug-print-function ${FUNCNAME} "$@"
	[[ ${#} -ge 1 ]] || die "${FUNCNAME} takes at least one arg: <subdir>"

	_DISTUTILS_SPHINX_SUBDIR=${1}
	shift
	_DISTUTILS_SPHINX_PLUGINS=( "${@}" )

	local deps autodoc=1 d
	deps=">=dev-python/sphinx-8.1.3[\${PYTHON_USEDEP}]"
	for d; do
		if [[ ${d} == --no-autodoc ]]; then
			autodoc=
		else
			deps+="
				${d}[\${PYTHON_USEDEP}]"
			if [[ ! ${autodoc} ]]; then
				die "${FUNCNAME}: do not pass --no-autodoc if external plugins are used"
			fi
		fi
	done

	if [[ ${autodoc} ]]; then
		if [[ ${DISTUTILS_SINGLE_IMPL} ]]; then
			deps="$(python_gen_cond_dep "${deps}")"
		else
			deps="$(python_gen_any_dep "${deps}")"
		fi

		python_check_deps() {
			use doc || return 0

			local p
			for p in ">=dev-python/sphinx-8.1.3" \
				"${_DISTUTILS_SPHINX_PLUGINS[@]}"
			do
				python_has_version "${p}[${PYTHON_USEDEP}]" ||
					return 1
			done
		}
	else
		deps=">=dev-python/sphinx-8.1.3"
	fi

	sphinx_compile_all() {
		use doc || return

		local confpy=${_DISTUTILS_SPHINX_SUBDIR}/conf.py
		[[ -f ${confpy} ]] ||
			die "${confpy} not found, distutils_enable_sphinx call wrong"

		if [[ ${_DISTUTILS_SPHINX_PLUGINS[0]} == --no-autodoc ]]; then
			if grep -F -q 'sphinx.ext.autodoc' "${confpy}"; then
				die "distutils_enable_sphinx: --no-autodoc passed but sphinx.ext.autodoc found in ${confpy}"
			fi
		elif [[ -z ${_DISTUTILS_SPHINX_PLUGINS[@]} ]]; then
			if ! grep -F -q 'sphinx.ext.autodoc' "${confpy}"; then
				die "distutils_enable_sphinx: sphinx.ext.autodoc not found in ${confpy}, pass --no-autodoc"
			fi
		fi

		build_sphinx "${_DISTUTILS_SPHINX_SUBDIR}"
	}
	python_compile_all() { sphinx_compile_all; }

	IUSE+=" doc"
	BDEPEND+=" doc? ( ${deps} )"

	# we need to ensure successful return in case we're called last,
	# otherwise Portage may wrongly assume sourcing failed
	return 0
}

# @FUNCTION: distutils_enable_tests
# @USAGE: <test-runner>
# @DESCRIPTION:
# Set up IUSE, RESTRICT, BDEPEND and python_test() for running tests
# with the specified test runner.  Also copies the current value
# of RDEPEND to test?-BDEPEND.  The test-runner argument must be one of:
#
# - import-check: `pytest --import-check` fallback (for use when there are
#   no tests to run)
#
# - pytest: dev-python/pytest
#
# - unittest: for built-in Python unittest module
#
# This function is meant as a helper for common use cases, and it only
# takes care of basic setup.  You still need to list additional test
# dependencies manually.  If you have uncommon use case, you should
# not use it and instead enable tests manually.
#
# This function must be called in global scope, after RDEPEND has been
# declared.  Take care not to overwrite the variables set by it.
distutils_enable_tests() {
	debug-print-function ${FUNCNAME} "$@"

	case ${1} in
		--install)
			die "${FUNCNAME} --install is no longer supported"
			;;
	esac

	[[ ${#} -eq 1 ]] || die "${FUNCNAME} takes exactly one argument: test-runner"

	local test_deps=${RDEPEND}
	local test_pkgs=
	case ${1} in
		import-check)
			test_pkgs+=' dev-python/pytest-import-check[${PYTHON_USEDEP}]'
			;&
		pytest)
			test_pkgs+=' >=dev-python/pytest-7.4.4[${PYTHON_USEDEP}]'
			if [[ -n ${EPYTEST_RERUNS} ]]; then
				test_pkgs+=' dev-python/pytest-rerunfailures[${PYTHON_USEDEP}]'
			fi
			if [[ -n ${EPYTEST_TIMEOUT} ]]; then
				test_pkgs+=' dev-python/pytest-timeout[${PYTHON_USEDEP}]'
			fi
			if [[ ${EPYTEST_XDIST} ]]; then
				test_pkgs+=' dev-python/pytest-xdist[${PYTHON_USEDEP}]'
			fi

			local plugin
			_set_epytest_plugins
			for plugin in "${EPYTEST_PLUGINS[@]}"; do
				case ${plugin} in
					${PN})
						# don't add a dependency on self
						continue
						;;
					pkgcore)
						plugin=sys-apps/${plugin}
						;;
					*)
						plugin=dev-python/${plugin}
						;;
				esac
				test_pkgs+=" ${plugin}[\${PYTHON_USEDEP}]"
			done

			if [[ ! ${DISTUTILS_SINGLE_IMPL} ]]; then
				test_deps+=" ${test_pkgs//'${PYTHON_USEDEP}'/${PYTHON_USEDEP}}"
			else
				test_deps+=" $(python_gen_cond_dep "
					${test_pkgs}
				")"
			fi
			;;
		unittest)
			;;
		*)
			die "${FUNCNAME}: unsupported argument: ${1}"
	esac

	_DISTUTILS_TEST_RUNNER=${1}
	python_test() { distutils-r1_python_test; }

	if [[ -n ${test_deps} ]]; then
		IUSE+=" test"
		RESTRICT+=" !test? ( test )"
		BDEPEND+=" test? ( ${test_deps} )"
	fi

	# we need to ensure successful return in case we're called last,
	# otherwise Portage may wrongly assume sourcing failed
	return 0
}

# @FUNCTION: esetup.py
# @USAGE: [<args>...]
# @DESCRIPTION:
# Run setup.py using currently selected Python interpreter
# (if ${EPYTHON} is set; fallback 'python' otherwise).
#
# setup.py will be passed the following, in order:
#
# 1. ${DISTUTILS_ARGS[@]}
#
# 2. ${mydistutilsargs[@]} (deprecated)
#
# 3. additional arguments passed to the esetup.py function.
#
# Please note that setup.py will respect defaults (unless overridden
# via command-line options) from setup.cfg that is created
# in distutils-r1_python_compile and in distutils-r1_python_install.
#
# This command dies on failure.
esetup.py() {
	debug-print-function ${FUNCNAME} "$@"

	_python_check_EPYTHON

	local setup_py=( setup.py )
	if [[ ! -f setup.py ]]; then
		setup_py=( -c "from setuptools import setup; setup()" )
	fi

	if [[ ${mydistutilsargs[@]} ]]; then
		die "mydistutilsargs is banned in EAPI ${EAPI} (use DISTUTILS_ARGS)"
	fi

	set -- "${EPYTHON}" "${setup_py[@]}" "${DISTUTILS_ARGS[@]}" \
		"${mydistutilsargs[@]}" "${@}"

	echo "${@}" >&2
	"${@}" || die -n
	local ret=${?}

	return ${ret}
}

# @FUNCTION: distutils_write_namespace
# @USAGE: <namespace>...
# @DESCRIPTION:
# Write the __init__.py file for the requested namespace into PEP517
# install tree, in order to fix running tests when legacy namespace
# packages are installed (dev-python/namespace-*).
#
# This function must only be used in python_test().  The created file
# will automatically be removed upon leaving the test phase.
distutils_write_namespace() {
	debug-print-function ${FUNCNAME} "$@"

	if [[ ${DISTUTILS_USE_PEP517} == no ]]; then
		die "${FUNCNAME} is available only with PEP517 backends"
	fi
	if [[ ${EBUILD_PHASE} != test || ! ${BUILD_DIR} ]]; then
		die "${FUNCNAME} should only be used in python_test"
	fi

	local namespace
	for namespace; do
		if [[ ${namespace} == *[./]* ]]; then
			die "${FUNCNAME} does not support nested namespaces at the moment"
		fi

		local path=${BUILD_DIR}/install$(python_get_sitedir)/${namespace}/__init__.py
		if [[ -f ${path} ]]; then
			die "Requested namespace ${path} exists already!"
		fi
		cat > "${path}" <<-EOF || die
			__path__ = __import__('pkgutil').extend_path(__path__, __name__)
		EOF
		_DISTUTILS_POST_PHASE_RM+=( "${path}" )
	done
}

# @FUNCTION: _distutils-r1_check_all_phase_mismatch
# @INTERNAL
# @DESCRIPTION:
# Verify whether *_all phase impls is not called from from non-*_all
# subphase.
_distutils-r1_check_all_phase_mismatch() {
	if has "python_${EBUILD_PHASE}" "${FUNCNAME[@]}"; then
		eqawarn "QA Notice: distutils-r1_python_${EBUILD_PHASE}_all called"
		eqawarn "from python_${EBUILD_PHASE}.  Did you mean to use"
		eqawarn "python_${EBUILD_PHASE}_all()?"
		die "distutils-r1_python_${EBUILD_PHASE}_all called from python_${EBUILD_PHASE}."
	fi
}

# @FUNCTION: _distutils-r1_print_package_versions
# @INTERNAL
# @DESCRIPTION:
# Print the version of the relevant build system packages to aid
# debugging.
_distutils-r1_print_package_versions() {
	local packages=(
		dev-python/gpep517
		dev-python/installer
	)
	if [[ ${DISTUTILS_EXT} ]]; then
		packages+=(
			dev-python/cython
		)
	fi
	case ${DISTUTILS_USE_PEP517} in
		flit)
			packages+=(
				dev-python/flit-core
			)
			;;
		flit_scm)
			packages+=(
				dev-python/flit-core
				dev-python/flit-scm
				dev-python/setuptools-scm
			)
			;;
		hatchling)
			packages+=(
				dev-python/hatchling
				dev-python/hatch-fancy-pypi-readme
				dev-python/hatch-vcs
			)
			;;
		jupyter)
			packages+=(
				dev-python/jupyter-packaging
				dev-python/setuptools
				dev-python/setuptools-scm
				dev-python/wheel
			)
			;;
		maturin)
			packages+=(
				dev-util/maturin
			)
			;;
		no)
			return
			;;
		meson-python)
			packages+=(
				dev-python/meson-python
			)
			;;
		pbr)
			packages+=(
				dev-python/pbr
				dev-python/setuptools
				dev-python/wheel
			)
			;;
		pdm-backend)
			packages+=(
				dev-python/pdm-backend
				dev-python/setuptools
			)
			;;
		poetry)
			packages+=(
				dev-python/poetry-core
			)
			;;
		scikit-build-core)
			packages+=(
				dev-python/scikit-build-core
			)
			;;
		setuptools)
			packages+=(
				dev-python/setuptools
				dev-python/setuptools-rust
				dev-python/setuptools-scm
				dev-python/wheel
			)
			;;
		sip)
			packages+=(
				dev-python/sip
			)
			;;
		uv-build)
			packages+=(
				dev-python/uv
				dev-python/uv-build
			)
			;;
	esac

	local pkg
	einfo "Build system packages:"
	for pkg in "${packages[@]}"; do
		local installed=$(best_version -b "${pkg}")
		einfo "  $(printf '%-30s' "${pkg}"): ${installed#${pkg}-}"
	done
}

# @FUNCTION: distutils-r1_python_prepare_all
# @DESCRIPTION:
# The default python_prepare_all(). It applies the patches from PATCHES
# array, then user patches and finally calls python_copy_sources to
# create copies of resulting sources for each Python implementation.
#
# At some point in the future, it may also apply eclass-specific
# distutils patches and/or quirks.
distutils-r1_python_prepare_all() {
	debug-print-function ${FUNCNAME} "$@"
	_python_sanity_checks
	_distutils-r1_check_all_phase_mismatch

	if [[ ! ${DISTUTILS_OPTIONAL} ]]; then
		default
	fi

	python_export_utf8_locale
	_distutils-r1_print_package_versions

	_DISTUTILS_DEFAULT_CALLED=1
}

# @FUNCTION: _distutils-r1_key_to_backend
# @USAGE: <key>
# @INTERNAL
# @DESCRIPTION:
# Print the backend corresponding to the DISTUTILS_USE_PEP517 value.
_distutils-r1_key_to_backend() {
	debug-print-function ${FUNCNAME} "$@"

	local key=${1}
	case ${key} in
		flit)
			echo flit_core.buildapi
			;;
		flit_scm)
			echo flit_scm:buildapi
			;;
		hatchling)
			echo hatchling.build
			;;
		jupyter)
			echo jupyter_packaging.build_api
			;;
		maturin)
			echo maturin
			;;
		meson-python)
			echo mesonpy
			;;
		pbr)
			echo pbr.build
			;;
		pdm-backend)
			echo pdm.backend
			;;
		poetry)
			echo poetry.core.masonry.api
			;;
		scikit-build-core)
			echo scikit_build_core.build
			;;
		setuptools)
			echo setuptools.build_meta
			;;
		sip)
			echo sipbuild.api
			;;
		uv-build)
			echo uv_build
			;;
		*)
			die "Unknown DISTUTILS_USE_PEP517 key: ${key}"
			;;
	esac
}

# @FUNCTION: _distutils-r1_get_backend
# @INTERNAL
# @DESCRIPTION:
# Read (or guess, in case of setuptools) the build-backend
# for the package in the current directory.
_distutils-r1_get_backend() {
	debug-print-function ${FUNCNAME} "$@"

	local build_backend
	if [[ -f pyproject.toml ]]; then
		# if pyproject.toml exists, try getting the backend from it
		# NB: this could fail if pyproject.toml doesn't list one
		build_backend=$("${EPYTHON}" -m gpep517 get-backend)
	fi
	if [[ -z ${build_backend} ]]; then
		if [[ ${DISTUTILS_USE_PEP517} == setuptools && -f setup.py ]]
		then
			# use the legacy setuptools backend as a fallback
			echo setuptools.build_meta:__legacy__
			return
		else
			die "Unable to obtain build-backend from pyproject.toml"
		fi
	fi

	# if DISTUTILS_USE_PEP517 is "standalone", we respect the exact
	# backend used in pyproject.toml; otherwise we force the backend
	# based on DISTUTILS_USE_PEP517
	if [[ ${DISTUTILS_USE_PEP517} == standalone ]]; then
		echo "${build_backend}"
		return
	fi

	# we can output it early, even if we die below
	echo "$(_distutils-r1_key_to_backend "${DISTUTILS_USE_PEP517}")"

	# skip backend verification if DISTUTILS_UPSTREAM_PEP517
	# is "standalone"
	if [[ ${DISTUTILS_UPSTREAM_PEP517} == standalone ]]; then
		return
	fi

	# verify that the ebuild correctly specifies the build backend
	local expected_backend=$(
		_distutils-r1_key_to_backend \
			"${DISTUTILS_UPSTREAM_PEP517:-${DISTUTILS_USE_PEP517}}"
	)
	if [[ ${expected_backend} != ${build_backend} ]]; then
		# special-case deprecated backends
		case ${build_backend} in
			flit.buildapi)
				;;
			pdm.pep517.api)
				;;
			poetry.masonry.api)
				;;
			setuptools.build_meta:__legacy__)
				;;
			uv)
				;;
			*)
				eerror "DISTUTILS_UPSTREAM_PEP517 does not match pyproject.toml!"
				eerror "  DISTUTILS_UPSTREAM_PEP517=${DISTUTILS_USE_PEP517}"
				eerror "  implies backend: ${expected_backend}"
				eerror "   pyproject.toml: ${build_backend}"
				die "DISTUTILS_USE_PEP517 value incorrect"
		esac

		# if we didn't die, we're dealing with a deprecated backend
		if [[ ! -f ${T}/.distutils_deprecated_backend_warned ]]; then
			eqawarn "QA Notice: ${build_backend} backend is deprecated.  Please see:"
			eqawarn "https://projects.gentoo.org/python/guide/qawarn.html#deprecated-pep-517-backends"
			eqawarn "The project should use ${expected_backend} instead."
			> "${T}"/.distutils_deprecated_backend_warned || die
		fi
	fi
}

# @FUNCTION: distutils_wheel_install
# @USAGE: <root> <wheel>
# @DESCRIPTION:
# Install the specified wheel into <root>.
#
# This function is intended for expert use only.
distutils_wheel_install() {
	debug-print-function ${FUNCNAME} "$@"
	if [[ ${#} -ne 2 ]]; then
		die "${FUNCNAME} takes exactly two arguments: <root> <wheel>"
	fi
	if [[ -z ${PYTHON} ]]; then
		die "PYTHON unset, invalid call context"
	fi

	local root=${1}
	local wheel=${2}

	einfo "  Installing ${wheel##*/} to ${root}"
	local cmd=(
		"${EPYTHON}" -m gpep517 install-wheel
			--destdir="${root}"
			--interpreter="${PYTHON}"
			--prefix="${EPREFIX}/usr"
			--optimize=all
			"${wheel}"
	)
	printf '%s\n' "${cmd[*]}"
	"${cmd[@]}" || die "Wheel install failed"

	# remove installed licenses and other junk
	find "${root}$(python_get_sitedir)" -depth \
		\( -ipath '*.dist-info/AUTHORS*' \
		-o -ipath '*.dist-info/CHANGELOG*' \
		-o -ipath '*.dist-info/CODE_OF_CONDUCT*' \
		-o -ipath '*.dist-info/COPYING*' \
		-o -ipath '*.dist-info/*LICEN[CS]E*' \
		-o -ipath '*.dist-info/NOTICE*' \
		-o -ipath '*.dist-info/*Apache*' \
		-o -ipath '*.dist-info/*GPL*' \
		-o -ipath '*.dist-info/*MIT*' \
		-o -path '*.dist-info/RECORD' \
		-o -path '*.dist-info/license_files/*' \
		-o -path '*.dist-info/license_files' \
		-o -path '*.dist-info/licenses/*' \
		-o -path '*.dist-info/licenses' \
		-o -path '*.dist-info/zip-safe' \
		\) -delete || die

	_DISTUTILS_WHL_INSTALLED=1
}

# @VARIABLE: DISTUTILS_WHEEL_PATH
# @DESCRIPTION:
# Path to the wheel created by distutils_pep517_install.

# @FUNCTION: distutils_pep517_install
# @USAGE: <root>
# @DESCRIPTION:
# Build the wheel for the package in the current directory using PEP517
# backend and install it into <root>.
#
# This function is intended for expert use only.  It does not handle
# wrapping executables.  The wheel path is returned
# in DISTUTILS_WHEEL_PATH variable.
distutils_pep517_install() {
	debug-print-function ${FUNCNAME} "$@"
	[[ ${#} -eq 1 ]] || die "${FUNCNAME} takes exactly one argument: root"

	if [[ ${DISTUTILS_USE_PEP517} == no ]]; then
		die "${FUNCNAME} is available only with PEP517 backend"
	fi

	local root=${1}
	export BUILD_DIR
	local -x WHEEL_BUILD_DIR=${BUILD_DIR}/wheel
	mkdir -p "${WHEEL_BUILD_DIR}" || die

	if [[ -n ${mydistutilsargs[@]} ]]; then
		die "mydistutilsargs are banned in PEP517 mode (use DISTUTILS_ARGS)"
	fi

	local cmd=() config_settings=
	if has cargo ${INHERITED} && [[ ${_CARGO_GEN_CONFIG_HAS_RUN} ]]; then
		cmd+=( cargo_env )
	fi

	# set it globally in case we were using "standalone" wrapper
	local -x FLIT_ALLOW_INVALID=1
	local -x HATCH_METADATA_CLASSIFIERS_NO_VERIFY=1
	local -x VALIDATE_PYPROJECT_NO_NETWORK=1
	local -x VALIDATE_PYPROJECT_NO_TROVE_CLASSIFIERS=1
	if in_iuse debug && use debug; then
		local -x SETUPTOOLS_RUST_CARGO_PROFILE=dev
	fi

	case ${DISTUTILS_USE_PEP517} in
		maturin)
			# `maturin pep517 build-wheel --help` for options
			local maturin_args=(
				"${DISTUTILS_ARGS[@]}"
				--auditwheel=skip # see bug #831171
				--jobs="$(makeopts_jobs)"
				$(in_iuse debug && usex debug '--profile=dev' '')
			)

			config_settings=$(
				"${EPYTHON}" - "${maturin_args[@]}" <<-EOF || die
					import json
					import sys
					print(json.dumps({"build-args": sys.argv[1:]}))
				EOF
			)
			;;
		meson-python)
			# variables defined by setup_meson_src_configure
			local MESONARGS=() BOOST_INCLUDEDIR BOOST_LIBRARYDIR NM READELF
			# it also calls filter-lto
			local x
			for x in $(all-flag-vars); do
				local -x "${x}=${!x}"
			done

			setup_meson_src_configure "${DISTUTILS_ARGS[@]}"

			local -x NINJAOPTS=$(get_NINJAOPTS)
			config_settings=$(
				"${EPYTHON}" - "${MESONARGS[@]}" <<-EOF || die
					import json
					import os
					import shlex
					import sys

					ninjaopts = shlex.split(os.environ["NINJAOPTS"])
					print(json.dumps({
						"builddir": "${BUILD_DIR}",
						"setup-args": sys.argv[1:],
						"compile-args": ["-v"] + ninjaopts,
					}))
				EOF
			)
			;;
		scikit-build-core)
			# TODO: split out the config/toolchain logic from cmake.eclass
			# for now, we copy the most important bits
			local CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE:-RelWithDebInfo}
			cat >> "${BUILD_DIR}"/config.cmake <<- _EOF_ || die
				set(CMAKE_ASM_FLAGS_${CMAKE_BUILD_TYPE^^} "" CACHE STRING "")
				set(CMAKE_ASM-ATT_FLAGS_${CMAKE_BUILD_TYPE^^} "" CACHE STRING "")
				set(CMAKE_C_FLAGS_${CMAKE_BUILD_TYPE^^} "" CACHE STRING "")
				set(CMAKE_CXX_FLAGS_${CMAKE_BUILD_TYPE^^} "" CACHE STRING "")
				set(CMAKE_Fortran_FLAGS_${CMAKE_BUILD_TYPE^^} "" CACHE STRING "")
				set(CMAKE_EXE_LINKER_FLAGS_${CMAKE_BUILD_TYPE^^} "" CACHE STRING "")
				set(CMAKE_MODULE_LINKER_FLAGS_${CMAKE_BUILD_TYPE^^} "" CACHE STRING "")
				set(CMAKE_SHARED_LINKER_FLAGS_${CMAKE_BUILD_TYPE^^} "" CACHE STRING "")
				set(CMAKE_STATIC_LINKER_FLAGS_${CMAKE_BUILD_TYPE^^} "" CACHE STRING "")
			_EOF_

			# hack around CMake ignoring CPPFLAGS
			local -x CFLAGS="${CFLAGS} ${CPPFLAGS}"
			local -x CXXFLAGS="${CXXFLAGS} ${CPPFLAGS}"

			local cmake_args=(
				"-C${BUILD_DIR}/config.cmake"
				"${DISTUTILS_ARGS[@]}"
			)

			local -x NINJAOPTS=$(get_NINJAOPTS)
			config_settings=$(
				"${EPYTHON}" - "${cmake_args[@]}" <<-EOF || die
					import json
					import os
					import shlex
					import sys

					ninjaopts = shlex.split(os.environ["NINJAOPTS"])
					print(json.dumps({
						"build.tool-args": ninjaopts,
						"cmake.args": ";".join(sys.argv[1:]),
						"cmake.build-type": "${CMAKE_BUILD_TYPE}",
						"cmake.verbose": True,
						"install.strip": False,
					}))
				EOF
			)
			;;
		setuptools)
			if [[ -n ${DISTUTILS_ARGS[@]} ]]; then
				config_settings=$(
					"${EPYTHON}" - "${DISTUTILS_ARGS[@]}" <<-EOF || die
						import json
						import sys
						print(json.dumps({"--build-option": sys.argv[1:]}))
					EOF
				)
			fi
			;;
		sip)
			if [[ -n ${DISTUTILS_ARGS[@]} ]]; then
				# NB: for practical reasons, we support only --foo=bar,
				# not --foo bar
				local arg
				for arg in "${DISTUTILS_ARGS[@]}"; do
					[[ ${arg} != -* ]] &&
						die "Bare arguments in DISTUTILS_ARGS unsupported: ${arg}"
				done

				config_settings=$(
					"${EPYTHON}" - "${DISTUTILS_ARGS[@]}" <<-EOF || die
						import collections
						import json
						import sys

						args = collections.defaultdict(list)
						for arg in (x.split("=", 1) for x in sys.argv[1:]): \
							args[arg[0]].extend(
								[arg[1]] if len(arg) > 1 else [])

						print(json.dumps(args))
					EOF
				)
			fi
			;;
		*)
			[[ -n ${DISTUTILS_ARGS[@]} ]] &&
				die "DISTUTILS_ARGS are not supported by ${DISTUTILS_USE_PEP517}"
			;;
	esac

	# https://pyo3.rs/latest/building-and-distribution.html#cross-compiling
	if tc-is-cross-compiler; then
		local -x PYO3_CROSS_LIB_DIR=${SYSROOT}/$(python_get_stdlib)
	fi

	local build_backend=$(_distutils-r1_get_backend)
	einfo "  Building the wheel for ${PWD#${WORKDIR}/} via ${build_backend}"
	cmd+=(
		"${EPYTHON}" -m gpep517 build-wheel
			--prefix="${EPREFIX}/usr"
			--backend "${build_backend}"
			--output-fd 3
			--wheel-dir "${WHEEL_BUILD_DIR}"
	)
	if [[ -n ${config_settings} ]]; then
		cmd+=( --config-json "${config_settings}" )
	fi
	if [[ -n ${SYSROOT} ]]; then
		cmd+=( --sysroot "${SYSROOT}" )
	fi
	printf '%s\n' "${cmd[*]}"
	local wheel=$(
		"${cmd[@]}" 3>&1 >&2 || die "Wheel build failed"
	)
	[[ -n ${wheel} ]] || die "No wheel name returned"

	distutils_wheel_install "${root}" "${WHEEL_BUILD_DIR}/${wheel}"

	DISTUTILS_WHEEL_PATH=${WHEEL_BUILD_DIR}/${wheel}
}

# @VARIABLE: DISTUTILS_WHEELS
# @DESCRIPTION:
# An associative array of wheels created as a result
# of distutils-r1_python_compile invocations, mapped to the source
# directories.  Note that this includes only wheels implicitly created
# by the eclass, and not wheels created as a result of direct
# distutils_pep517_install calls in the ebuild.
declare -g -A DISTUTILS_WHEELS=()

# @FUNCTION: distutils-r1_python_compile
# @USAGE: [additional-args...]
# @DESCRIPTION:
# The default python_compile().
#
# If DISTUTILS_USE_PEP517 is set to "no", a no-op.
#
# If DISTUTILS_USE_PEP517 is set to any other value, builds a wheel
# using the PEP517 backend and installs it into ${BUILD_DIR}/install.
# Path to the wheel is then added to DISTUTILS_WHEELS array.
distutils-r1_python_compile() {
	debug-print-function ${FUNCNAME} "$@"

	_python_check_EPYTHON

	[[ ${DISTUTILS_USE_PEP517} == no ]] && return

	# we do this for all build systems, since other backends
	# and custom hooks may wrap setuptools
	#
	# we are appending a dynamic component so that
	# distutils-r1_python_compile can be called multiple
	# times and don't end up combining resulting packages
	mkdir -p "${BUILD_DIR}" || die
	local -x DIST_EXTRA_CONFIG="${BUILD_DIR}/extra-setup.cfg"
	cat > "${DIST_EXTRA_CONFIG}" <<-EOF || die
		[build]
		build_base = ${BUILD_DIR}/build${#DISTUTILS_WHEELS[@]}

		[build_ext]
		parallel = $(makeopts_jobs "${MAKEOPTS} ${*}")
	EOF

	if [[ ${DISTUTILS_ALLOW_WHEEL_REUSE} ]]; then
		local whl
		for whl in "${!DISTUTILS_WHEELS[@]}"; do
			# use only wheels corresponding to the current directory
			if [[ ${PWD} != ${DISTUTILS_WHEELS["${whl}"]} ]]; then
				continue
			fi

			# 1. Use pure Python wheels only if we're not expected
			# to build extensions.  Otherwise, we may end up
			# not building the extension at all when e.g. PyPy3
			# is built without one.
			#
			# 2. For CPython, we can reuse stable ABI wheels.  Note
			# that this relies on the assumption that we're building
			# from the oldest to the newest implementation,
			# and the wheels are forward-compatible.
			if [[
				( ! ${DISTUTILS_EXT} && ${whl} == *py3-none-any* ) ||
				(
					${EPYTHON} == python* &&
					# freethreading does not support stable ABI
					# at the moment
					${EPYTHON} != *t &&
					${whl} == *-abi3-*
				)
			]]; then
				distutils_wheel_install "${BUILD_DIR}/install" "${whl}"
				return
			fi
		done
	fi

	distutils_pep517_install "${BUILD_DIR}/install"
	DISTUTILS_WHEELS+=( "${DISTUTILS_WHEEL_PATH}" "${PWD}" )
}

# @FUNCTION: _distutils-r1_wrap_scripts
# @USAGE: <bindir>
# @INTERNAL
# @DESCRIPTION:
# Moves and wraps all installed scripts/executables as necessary.
_distutils-r1_wrap_scripts() {
	debug-print-function ${FUNCNAME} "$@"

	[[ ${#} -eq 1 ]] || die "usage: ${FUNCNAME} <bindir>"
	local bindir=${1}

	local scriptdir=$(python_get_scriptdir)
	local f python_files=() non_python_files=()

	if [[ -d ${D}${scriptdir} ]]; then
		for f in "${D}${scriptdir}"/*; do
			[[ -d ${f} ]] && die "Unexpected directory: ${f}"
			debug-print "${FUNCNAME}: found executable at ${f#${D}/}"

			local shebang
			read -r shebang < "${f}"
			if [[ ${shebang} == '#!'*${EPYTHON}* ]]; then
				debug-print "${FUNCNAME}: matching shebang: ${shebang}"
				python_files+=( "${f}" )
			else
				debug-print "${FUNCNAME}: non-matching shebang: ${shebang}"
				non_python_files+=( "${f}" )
			fi

			mkdir -p "${D}${bindir}" || die
		done

		for f in "${python_files[@]}"; do
			local basename=${f##*/}

			debug-print "${FUNCNAME}: installing wrapper at ${bindir}/${basename}"
			dosym -r /usr/lib/python-exec/python-exec2 \
				"${bindir#${EPREFIX}}/${basename}"
		done

		for f in "${non_python_files[@]}"; do
			local basename=${f##*/}

			debug-print "${FUNCNAME}: moving ${f#${D}/} to ${bindir}/${basename}"
			mv "${f}" "${D}${bindir}/${basename}" || die
		done
	fi
}

# @FUNCTION: distutils-r1_python_test
# @USAGE: [additional-args...]
# @DESCRIPTION:
# The python_test() implementation used by distutils_enable_tests.
# Runs tests using the specified test runner, possibly installing them
# first.
#
# This function is used only if distutils_enable_tests is called.
distutils-r1_python_test() {
	debug-print-function ${FUNCNAME} "$@"

	if [[ -z ${_DISTUTILS_TEST_RUNNER} ]]; then
		die "${FUNCNAME} can be only used after calling distutils_enable_tests"
	fi

	_python_check_EPYTHON

	case ${_DISTUTILS_TEST_RUNNER} in
		import-check)
			epytest --import-check "${BUILD_DIR}/install$(python_get_sitedir)"
			;;
		pytest)
			epytest
			;;
		unittest)
			eunittest
			;;
		*)
			die "Mis-synced test runner between ${FUNCNAME} and distutils_enable_testing"
			;;
	esac

	if [[ ${?} -ne 0 ]]; then
		die -n "Tests failed with ${EPYTHON}"
	fi
}

# @FUNCTION: distutils-r1_python_install
# @USAGE: [additional-args...]
# @DESCRIPTION:
# The default python_install().  Merges the files
# from ${BUILD_DIR}/install (if present) to the image directory.
distutils-r1_python_install() {
	debug-print-function ${FUNCNAME} "$@"

	_python_check_EPYTHON

	local scriptdir=${EPREFIX}/usr/bin
	local merge_root=
	local root=${BUILD_DIR}/install
	local reg_scriptdir=${root}/${scriptdir}
	local wrapped_scriptdir=${root}$(python_get_scriptdir)

	# we are assuming that _distutils-r1_post_python_compile
	# has been called and ${root} has not been altered since
	# let's explicitly verify these assumptions

	# remove files that we've created explicitly
	rm "${reg_scriptdir}"/{"${EPYTHON}",python3,python} || die
	rm "${reg_scriptdir}"/../pyvenv.cfg || die

	# Automagically do the QA check to avoid issues when bootstrapping
	# prefix.
	if type diff &>/dev/null ; then
		# verify that scriptdir & wrapped_scriptdir both contain
		# the same files
		(
			cd "${reg_scriptdir}" && find . -mindepth 1
		) | sort > "${T}"/.distutils-files-bin
		assert "listing ${reg_scriptdir} failed"
		(
			if [[ -d ${wrapped_scriptdir} ]]; then
				cd "${wrapped_scriptdir}" && find . -mindepth 1
			fi
		) | sort > "${T}"/.distutils-files-wrapped
		assert "listing ${wrapped_scriptdir} failed"
		if ! diff -U 0 "${T}"/.distutils-files-{bin,wrapped}; then
			die "File lists for ${reg_scriptdir} and ${wrapped_scriptdir} differ (see diff above)"
		fi
	fi

	# remove the altered bindir, executables from the package
	# are already in scriptdir
	rm -r "${reg_scriptdir}" || die
	if [[ ${DISTUTILS_SINGLE_IMPL} ]]; then
		if [[ -d ${wrapped_scriptdir} ]]; then
			mv "${wrapped_scriptdir}" "${reg_scriptdir}" || die
		fi
	fi
	# prune empty directories to see if ${root} contains anything
	# to merge
	find "${BUILD_DIR}"/install -type d -empty -delete || die
	[[ -d ${BUILD_DIR}/install ]] && merge_root=1

	if [[ ${merge_root} ]]; then
		multibuild_merge_root "${root}" "${D}"
	fi
	if [[ ! ${DISTUTILS_SINGLE_IMPL} ]]; then
		_distutils-r1_wrap_scripts "${scriptdir}"
	fi
}

# @FUNCTION: distutils-r1_python_install_all
# @DESCRIPTION:
# The default python_install_all(). It installs the documentation.
distutils-r1_python_install_all() {
	debug-print-function ${FUNCNAME} "$@"
	_distutils-r1_check_all_phase_mismatch

	einstalldocs
}

# @FUNCTION: distutils-r1_run_phase
# @USAGE: [<argv>...]
# @INTERNAL
# @DESCRIPTION:
# Run the given command.
#
# If out-of-source builds are used, the phase function is run in source
# directory, with BUILD_DIR pointing at the build directory
# and PYTHONPATH having an entry for the module build directory.
#
# If in-source builds are used, the command is executed in the directory
# holding the per-implementation copy of sources. BUILD_DIR points
# to the 'build' subdirectory.
distutils-r1_run_phase() {
	debug-print-function ${FUNCNAME} "$@"

	local -x PATH=${BUILD_DIR}/install${EPREFIX}/usr/bin:${PATH}
	# Set up build environment, bug #513664.
	local -x AR=${AR} CC=${CC} CPP=${CPP} CXX=${CXX}
	tc-export AR CC CPP CXX

	# Perform additional environment modifications only for python_compile
	# phase.  This is the only phase where we expect to be calling the Python
	# build system.  We want to localize the altered variables to avoid them
	# leaking to other parts of multi-language ebuilds.  However, we want
	# to avoid localizing them in other phases, particularly
	# python_configure_all, where the ebuild may wish to alter them globally.
	if [[ ${DISTUTILS_EXT} && ( ${1} == *compile* || ${1} == *test* ) ]]; then
		local -x CPPFLAGS="${CPPFLAGS} $(usex debug '-UNDEBUG' '-DNDEBUG')"
		# always generate .c files from .pyx files to ensure we get latest
		# bug fixes from Cython (this works only when setup.py is using
		# cythonize() but it's better than nothing)
		local -x CYTHON_FORCE_REGEN=1
	fi

	# silence warnings when pydevd is loaded on Python 3.11+
	local -x PYDEVD_DISABLE_FILE_VALIDATION=1

	# How to build Python modules in different worlds...
	local ldopts
	case "${CHOST}" in
		# provided by grobian, 2014-06-22, bug #513664 c7
		*-darwin*) ldopts='-bundle -undefined dynamic_lookup';;
		*) ldopts='-shared';;
	esac

	local -x LDSHARED="${CC} ${ldopts}" LDCXXSHARED="${CXX} ${ldopts}"
	local _DISTUTILS_POST_PHASE_RM=()

	"${@}"
	local ret=${?}

	if [[ -n ${_DISTUTILS_POST_PHASE_RM} ]]; then
		rm "${_DISTUTILS_POST_PHASE_RM[@]}" || die
	fi

	cd "${_DISTUTILS_INITIAL_CWD}" || die
	if [[ ! ${_DISTUTILS_IN_COMMON_IMPL} ]] &&
		declare -f "_distutils-r1_post_python_${EBUILD_PHASE}" >/dev/null
	then
		"_distutils-r1_post_python_${EBUILD_PHASE}"
	fi
	return "${ret}"
}

# @FUNCTION: _distutils-r1_run_common_phase
# @USAGE: [<argv>...]
# @INTERNAL
# @DESCRIPTION:
# Run the given command, restoring the state for a most preferred Python
# implementation matching DISTUTILS_ALL_SUBPHASE_IMPLS.
#
# If in-source build is used, the command will be run in the copy
# of sources made for the selected Python interpreter.
_distutils-r1_run_common_phase() {
	local DISTUTILS_ORIG_BUILD_DIR=${BUILD_DIR}
	local _DISTUTILS_IN_COMMON_IMPL=1

	if [[ ${DISTUTILS_SINGLE_IMPL} ]]; then
		# reuse the dedicated code branch
		_distutils-r1_run_foreach_impl "${@}"
	else
		local -x EPYTHON PYTHON
		local -x PATH=${PATH} PKG_CONFIG_PATH=${PKG_CONFIG_PATH}
		python_setup "${DISTUTILS_ALL_SUBPHASE_IMPLS[@]}"

		local MULTIBUILD_VARIANTS=( "${EPYTHON/./_}" )
		# store for restoring after distutils-r1_run_phase.
		local _DISTUTILS_INITIAL_CWD=${PWD}
		multibuild_foreach_variant \
			distutils-r1_run_phase "${@}"
	fi
}

# @FUNCTION: _distutils-r1_run_foreach_impl
# @INTERNAL
# @DESCRIPTION:
# Run the given phase for each implementation if multiple implementations
# are enabled, once otherwise.
_distutils-r1_run_foreach_impl() {
	debug-print-function ${FUNCNAME} "$@"

	# store for restoring after distutils-r1_run_phase.
	local _DISTUTILS_INITIAL_CWD=${PWD}
	set -- distutils-r1_run_phase "${@}"

	if [[ ! ${DISTUTILS_SINGLE_IMPL} ]]; then
		local _DISTUTILS_CALLING_FOREACH_IMPL=1
		python_foreach_impl "${@}"
	else
		if [[ ! ${EPYTHON} ]]; then
			die "EPYTHON unset, python-single-r1_pkg_setup not called?!"
		fi
		local BUILD_DIR=${BUILD_DIR:-${S}}
		BUILD_DIR=${BUILD_DIR%%/}_${EPYTHON}

		"${@}"
	fi
}

distutils-r1_src_prepare() {
	debug-print-function ${FUNCNAME} "$@"
	local ret=0
	local _DISTUTILS_DEFAULT_CALLED

	# common preparations
	if declare -f python_prepare_all >/dev/null; then
		python_prepare_all || ret=${?}
	else
		distutils-r1_python_prepare_all || ret=${?}
	fi

	if [[ ! ${_DISTUTILS_DEFAULT_CALLED} ]]; then
		die "QA: python_prepare_all() didn't call distutils-r1_python_prepare_all"
	fi

	if declare -f python_prepare >/dev/null; then
		_distutils-r1_run_foreach_impl python_prepare || ret=${?}
	fi

	return ${ret}
}

distutils-r1_src_configure() {
	debug-print-function ${FUNCNAME} "$@"
	local ret=0

	if declare -f python_configure >/dev/null; then
		_distutils-r1_run_foreach_impl python_configure || ret=${?}
	fi

	if declare -f python_configure_all >/dev/null; then
		_distutils-r1_run_common_phase python_configure_all || ret=${?}
	fi

	return ${ret}
}

# @FUNCTION: _distutils-r1_compare_installed_files
# @INTERNAL
# @DESCRIPTION:
# Verify the the match between files installed between this and previous
# implementation.
_distutils-r1_compare_installed_files() {
	debug-print-function ${FUNCNAME} "$@"

	# QA check requires diff(1).
	if ! type -P diff &>/dev/null; then
		return
	fi

	# Perform the check only if at least one potentially reusable wheel
	# has been produced.  Nonpure packages (e.g. NumPy) may install
	# interpreter configuration details into sitedir.
	if [[ ${!DISTUTILS_WHEELS[*]} != *py3-none-any.whl* &&
			${!DISTUTILS_WHEELS[*]} != *-abi3-*.whl ]]; then
		return
	fi

	local sitedir=${BUILD_DIR}/install$(python_get_sitedir)
	if [[ -n ${_DISTUTILS_PREVIOUS_SITE} ]]; then
		diff -dur \
			--exclude=__pycache__ \
			--exclude='*.dist-info' \
			--exclude="*$(get_modname)" \
			"${_DISTUTILS_PREVIOUS_SITE}" "${sitedir}"
		if [[ ${?} -ne 0 ]]; then
			eqawarn "QA Notice: Package creating at least one pure Python wheel installs different"
			eqawarn "Python files between implementations.  See diff in build log, above"
			eqawarn "this message."
		fi
	fi

	_DISTUTILS_PREVIOUS_SITE=${sitedir}
}

# @FUNCTION: _distutils-r1_post_python_compile
# @INTERNAL
# @DESCRIPTION:
# Post-phase function called after python_compile.  In PEP517 mode,
# it adjusts the install tree for venv-style usage.
_distutils-r1_post_python_compile() {
	debug-print-function ${FUNCNAME} "$@"

	if [[ ! ${_DISTUTILS_WHL_INSTALLED} && ${DISTUTILS_USE_PEP517} != no ]]
	then
		die "No wheel installed in python_compile(), did you call distutils-r1_python_compile?"
	fi

	local root=${BUILD_DIR}/install
	if [[ -d ${root} ]]; then
		# copy executables to python-exec directory
		# we do it early so that we can alter bindir recklessly
		local bindir=${root}${EPREFIX}/usr/bin
		local rscriptdir=${root}$(python_get_scriptdir)
		[[ -d ${rscriptdir} ]] &&
			die "${rscriptdir} should not exist!"
		if [[ -d ${bindir} ]]; then
			mkdir -p "${rscriptdir}" || die
			cp -a "${bindir}"/. "${rscriptdir}"/ || die
		fi

		# enable venv magic inside the install tree
		mkdir -p "${bindir}" || die
		ln -s "${PYTHON}" "${bindir}/${EPYTHON}" || die
		ln -s "${EPYTHON}" "${bindir}/python3" || die
		ln -s "${EPYTHON}" "${bindir}/python" || die
		# python3.14 changed venv logic so that:
		# 1) pyvenv.cfg location explicitly determines prefix
		#    (i.e. we no longer can be put in bin/)
		# 2) "home =" key must be present
		cat > "${bindir}"/../pyvenv.cfg <<-EOF || die
			home = ${EPREFIX}/usr/bin
			include-system-site-packages = true
		EOF

		# we need to change shebangs to point to the venv-python
		find "${bindir}" -type f -exec sed -i \
			-e "1s@^#!\(${EPREFIX}/usr/bin/\(python\|pypy\)\)@#!${root}\1@" \
			{} + || die

		_distutils-r1_compare_installed_files
	fi
}

distutils-r1_src_compile() {
	debug-print-function ${FUNCNAME} "$@"
	local ret=0

	if declare -f python_compile >/dev/null; then
		_distutils-r1_run_foreach_impl python_compile || ret=${?}
	else
		_distutils-r1_run_foreach_impl distutils-r1_python_compile || ret=${?}
	fi

	if declare -f python_compile_all >/dev/null; then
		_distutils-r1_run_common_phase python_compile_all || ret=${?}
	fi

	return ${ret}
}

distutils-r1_src_test() {
	debug-print-function ${FUNCNAME} "$@"
	local ret=0

	if declare -f python_test >/dev/null; then
		_distutils-r1_run_foreach_impl python_test || ret=${?}
	fi

	if declare -f python_test_all >/dev/null; then
		_distutils-r1_run_common_phase python_test_all || ret=${?}
	fi

	return ${ret}
}

# @FUNCTION: _distutils-r1_strip_namespace_packages
# @USAGE: <sitedir>
# @INTERNAL
# @DESCRIPTION:
# Find and remove setuptools-style namespaces in the specified
# directory.
_distutils-r1_strip_namespace_packages() {
	debug-print-function ${FUNCNAME} "$@"

	local sitedir=${1}
	local f ns had_any=
	while IFS= read -r -d '' f; do
		while read -r ns; do
			einfo "Stripping pkg_resources-style namespace ${ns}"
			had_any=1
		done < "${f}"

		rm "${f}" || die
	done < <(
		# NB: this deliberately does not include .egg-info, in order
		# to limit this to PEP517 mode.
		find "${sitedir}" -path '*.dist-info/namespace_packages.txt' -print0
	)

	# If we had any namespace packages, remove .pth files as well.
	if [[ ${had_any} ]]; then
		find "${sitedir}" -name '*-nspkg.pth' -delete || die
	fi
}

# @FUNCTION: _distutils-r1_post_python_install
# @INTERNAL
# @DESCRIPTION:
# Post-phase function called after python_install.  Performs QA checks.
# In PEP517 mode, additionally optimizes installed Python modules.
_distutils-r1_post_python_install() {
	debug-print-function ${FUNCNAME} "$@"

	local sitedir=${D}$(python_get_sitedir)
	if [[ -d ${sitedir} ]]; then
		_distutils-r1_strip_namespace_packages "${sitedir}"

		local forbidden_package_names=(
			examples test tests
			.pytest_cache .hypothesis _trial_temp
		)
		local strays=()
		local p
		mapfile -d $'\0' -t strays < <(
			# jar for jpype, https://bugs.gentoo.org/937642
			find "${sitedir}" -maxdepth 1 -type f '!' '(' \
					-name '*.egg-info' -o \
					-name '*.jar' -o \
					-name '*.pth' -o \
					-name '*.py' -o \
					-name '*.pyi' -o \
					-name "*$(get_modname)" \
				')' -print0
		)
		for p in "${forbidden_package_names[@]}"; do
			[[ -d ${sitedir}/${p} ]] && strays+=( "${sitedir}/${p}" )
		done

		if [[ -n ${strays[@]} ]]; then
			eerror "The following unexpected files/directories were found top-level"
			eerror "in the site-packages directory:"
			eerror
			for p in "${strays[@]}"; do
				eerror "  ${p#${ED}}"
			done
			eerror
			eerror "This is most likely a bug in the build system.  More information"
			eerror "can be found in the Python Guide:"
			eerror "https://projects.gentoo.org/python/guide/qawarn.html#stray-top-level-files-in-site-packages"
			die "Failing install because of stray top-level files in site-packages"
		fi

		if [[ ! ${DISTUTILS_EXT} && ! ${_DISTUTILS_EXT_WARNED} ]]; then
			if [[ $(find "${sitedir}" -name "*$(get_modname)" | head -n 1) ]]
			then
				eqawarn "QA Notice: Python extension modules (*$(get_modname)) found installed. Please set:"
				eqawarn "  DISTUTILS_EXT=1"
				eqawarn "in the ebuild."
				_DISTUTILS_EXT_WARNED=1
			fi
		fi
	fi
}

# @FUNCTION: _distutils-r1_check_namespace_pth
# @INTERNAL
# @DESCRIPTION:
# Check if any *-nspkg.pth files were installed (by setuptools)
# and warn about the policy non-conformance if they were.
_distutils-r1_check_namespace_pth() {
	local f pth=()

	while IFS= read -r -d '' f; do
		pth+=( "${f}" )
	done < <(find "${ED}" -name '*-nspkg.pth' -print0)

	if [[ ${pth[@]} ]]; then
		eerror "The following *-nspkg.pth files were found installed:"
		eerror
		for f in "${pth[@]}"; do
			eerror "  ${f#${ED}}"
		done
		eerror
		eerror "The presence of those files may break namespaces in Python 3.5+. Please"
		eerror "read our documentation on reliable handling of namespaces and update"
		eerror "the ebuild accordingly:"
		eerror
		eerror "  https://projects.gentoo.org/python/guide/concept.html#namespace-packages"

		die "Installing *-nspkg.pth files is banned"
	fi
}

distutils-r1_src_install() {
	debug-print-function ${FUNCNAME} "$@"
	local ret=0

	if declare -f python_install >/dev/null; then
		_distutils-r1_run_foreach_impl python_install || ret=${?}
	else
		_distutils-r1_run_foreach_impl distutils-r1_python_install || ret=${?}
	fi

	if declare -f python_install_all >/dev/null; then
		_distutils-r1_run_common_phase python_install_all || ret=${?}
	else
		_distutils-r1_run_common_phase distutils-r1_python_install_all || ret=${?}
	fi

	_distutils-r1_check_namespace_pth

	return ${ret}
}

fi

if [[ ! ${DISTUTILS_OPTIONAL} ]]; then
	EXPORT_FUNCTIONS src_prepare src_configure src_compile src_test src_install
fi
