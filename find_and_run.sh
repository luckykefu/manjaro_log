#!/bin/bash
find_and_run() {
	local dir=${1:-.}
	local file=$2
	local func=${file%.sh}
	shift 2

	local script
	script=$(find "$dir" -type f -name "$file" -print -quit)

	if [[ -z "$script" ]]; then
		echo "Error: $file not found in $dir" >&2
		return 1
	fi

	echo "Running $script -> $func"
	# shellcheck disable=SC1090
	source "$script"

	if ! declare -F "$func" >/dev/null; then
		echo "Error: function '$func' not found in $script" >&2
		return 2
	fi

	"$func" "$@"
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && find_and_run "$@"
