#!/bin/bash
clone_create_conda_env() {
	local clone_dir=$1
	local url=$2
	local python_ver=${3:-3.12}
	local conda_path=${4:-${CONDA_EXE:-/data/.path/.miniconda3/bin/conda}}
	local name=$(basename "$url" .git)
	local target_dir="$clone_dir/$name"

	# Create clone directory
	mkdir -p "$clone_dir"
	cd "$clone_dir" || return 1

	# Clone repository
	if [[ ! -d "$name" ]]; then
		git clone "$url"
		echo "✓ Cloned $name"
	else
		echo "✓ $name already exists"
	fi

	# Create conda environment
	if "$conda_path" env list | grep -q "^$name "; then
		echo "✓ Conda environment $name already exists"
	else
		"$conda_path" create -n "$name" python="$python_ver" ipykernel -y
		echo "✓ Created conda environment: $name"
	fi

	# Install requirements if exists
	if [[ -f "$name/requirements.txt" ]]; then
		"$conda_path" run -n "$name" pip install -r "$name/requirements.txt"
		echo "✓ Installed requirements"
	fi
}
