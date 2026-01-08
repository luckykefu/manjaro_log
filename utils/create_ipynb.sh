#!/bin/bash
create_ipynb() {
	dir="$1"
	title="$2"
	file="$dir/${title}.ipynb"

	[[ -f "$file" ]] && echo "File already exists:  $file" && return

	mkdir -p "$dir"
	cat >"$file" <<'EOF'
{
	"cells": [
		{
			"cell_type": "markdown",
			"id": "1",
			"metadata": {},
			"source": [
				"# TITLE\n"
			]
		},
		{
			"cell_type": "code",
			"execution_count": null,
			"id": "2",
			"metadata": {},
			"outputs": [],
			"source": [
				"!pwd\n"
			]
		}
	],
	"metadata": {
		"language_info": {
			"name": "python"
		}
	},
	"nbformat": 4,
	"nbformat_minor": 5
}
EOF

	sed -i "s/TITLE/$title/" "$file"
	echo "Created: $file"
}
