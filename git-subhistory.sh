#!/bin/sh
# http://github.com/laughinghan/git-subhistory

# util fn (at the top 'cos used in options parsing)
die () {
	echo "fatal:" "$@" >&2
	exit 1
}

######################
# Options Parsing
#   >:( so many lines

# if zero args, default to -h
test $# = 0 && set -- -h

OPTS_SPEC="\
git-subhistory split <subproj-path> (-b | -B) <subproj-branch>
git-subhistory merge <subproj-path> <subproj-branch>
--
q,quiet         be quiet
v,verbose       be verbose
h               show the help

 options for 'split':
b=              create a new branch for the split-out commit history
B=              like -b but force creation"

eval "$(echo "$OPTS_SPEC" | git rev-parse --parseopt -- "$@" || echo exit $?)"
# ^ this is actually what you're supposed to do, see `git rev-parse --help`

quiet="$GIT_QUIET"
verbose=
newbranch=
force_newbranch=

while test $# != 0
do
	case "$1" in
	-q|--quiet) quiet=1 ;;
	--no-quiet) quiet= ;;
	-v|--verbose) verbose=1 ;;
	--no-verbose) verbose= ;;
	-b|-B)
		test "$1" = "-B" && force_newbranch=-f
		shift
		newbranch="$1"
		test "$newbranch" || die "branch name must be nonempty"
	;;
	--) break ;;
	esac
	shift
done
shift

##############
# Logging Fns

if test "$quiet"
then
	say () {
		:
	}
	say_stdin () {
		cat >/dev/null
	}
else
	say () {
		echo "$@" >&2
	}
	say_stdin () {
		cat >&2
	}
fi

if test "$verbose" -a ! "$quiet"
then
	elaborate () {
		echo "$@" >&2
	}
else
	elaborate () {
		:
	}
fi

usage () {
	echo "$@" >&2
	echo >&2
	exec "$0" -h
}

##############
# Subcommands

subhistory_split () {
	test "$newbranch" || usage "branch name required for 'split'"

	test $# = 1 || usage "wrong number of arguments to 'split'"
	subproj_path="$1"
	test -d "$subproj_path" || die "$subproj_path: Not a directory"

	elaborate "'split' subproj_path='$subproj_path' newbranch='$newbranch'" \
		"force_newbranch='$force_newbranch'"

	rm -rf "$(git rev-parse --git-dir)/refs/subhistory-tmp"

	git branch "$newbranch" $force_newbranch || exit $?
	git filter-branch \
		--original refs/subhistory-tmp \
		--subdirectory-filter "$subproj_path" \
		-- "$newbranch" \
		2>&1 | say_stdin || exit $?

	rm -rf "$(git rev-parse --git-dir)/refs/subhistory-tmp"
}

subhistory_merge () {
	die "'$subcommand' not yet implemented"
}

#######
# Main

subcommand="$1"
shift

case "$subcommand" in
	split|merge) ;;
	*) usage "unknown subcommand '$subcommand'" ;;
esac

"subhistory_$subcommand" "$@"
