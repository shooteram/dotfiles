glt() {
	if [[ $1 == "" ]]; then
		echo "please, specify an argument"
		return
	fi

	git fetch --tags --force &> /dev/null

	IFS='.'
	versions=($(git tag --sort=v:refname | tail -1 | sed -e 's/v//g'))
	unset IFS

	case $1 in
		r*) echo "v$(( $versions[1] + 1 )).$versions[2].$versions[3]";;
		f*) echo "v$versions[1].$(( $versions[2] + 1 )).$versions[3]";;
		h*) echo "v$versions[1].$versions[2].$(( $versions[3] + 1 ))";;
		*) echo "please, specify a correct keyword"
			echo "correct keywords are: release, feature, hotfix"
			return;;
	esac

	unset versions
}

hotfix_version()  { glt hotfix 	}
release_version() { glt release }
feature_version() { glt feature }

alias _hot=hotfix_version
alias _rel=release_version
alias _fea=feature_version

# define a path for git hooks (if it ain't already defined ofc)
git config --global core.hooksPath &> /dev/null
if [[ ! $? -eq 0 ]]; then
    git config --global core.hooksPath "$__dir/git/hooks"
fi
