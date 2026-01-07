#!/bin/bash
find_and_run() {
	local file=$1 func=${1%.sh}
	shift 1

	local script
	script=$(find . -type f -name "$file" -print -quit)

	if [[ -z "$script" ]]; then
		echo "Error: $file not found" >&2
		return 1
	fi

	echo "Running $script -> $func"
	source "$script"

	if ! declare -F "$func" >/dev/null; then
		echo "Error: function '$func' not found in $script" >&2
		return 2
	fi

	"$func" "$@"
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && find_and_run "$@"
