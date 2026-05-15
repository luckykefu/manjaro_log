#!/usr/bin/env bash
## Brief: Install and apply KDE theme
## Args: [theme_repo] [theme_name]

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/config.sh"

cmd_theme() {
  ## Brief: Clone and install KDE theme
  ## Args: theme_repo (default env), theme_name (default env)

  load_config

  local repo="${1:-${THEME_REPO}}"
  local theme_name="${2:-${THEME_NAME}}"
  local tmp_dir="/tmp/kde-theme-$$"

  log_info "Installing theme: ${theme_name} from ${repo}"

  if [[ -d "${tmp_dir}" ]]; then
    exec_cmd rm -rf "${tmp_dir}"
  fi

  exec_cmd git clone --depth 1 --branch "${THEME_BRANCH}" "${repo}" "${tmp_dir}"

  local theme_src="${tmp_dir}"

  for dir in plasma desktoptheme color-schemes aurorae Kvantum icons sddm look-and-feel; do
    local src_path="${theme_src}/${dir}"
    if [[ ! -d "${src_path}" ]]; then
      log_debug "Skipping missing theme dir: ${dir}"
      continue
    fi
    case "${dir}" in
      plasma)
        exec_cmd cp -r "${src_path}/desktoptheme/"* "${THEME_DIR}/"
        log_info "Copied plasma desktop themes"
        ;;
      desktoptheme)
        exec_cmd mkdir -p "${THEME_DIR}"
        exec_cmd cp -r "${src_path}/"* "${THEME_DIR}/"
        log_info "Copied desktop themes"
        ;;
      color-schemes)
        exec_cmd mkdir -p "${COLOR_SCHEMES_DIR}"
        exec_cmd cp -r "${src_path}/"* "${COLOR_SCHEMES_DIR}/"
        log_info "Copied color schemes"
        ;;
      aurorae)
        exec_cmd mkdir -p "${AURORAE_DIR}"
        exec_cmd cp -r "${src_path}/"* "${AURORAE_DIR}/"
        log_info "Copied aurorae themes"
        ;;
      Kvantum)
        exec_cmd mkdir -p "${KVANTUM_DIR}"
        exec_cmd cp -r "${src_path}/"* "${KVANTUM_DIR}/"
        log_info "Copied Kvantum themes"
        ;;
      icons)
        exec_cmd mkdir -p "${ICONS_DIR}"
        exec_cmd cp -r "${src_path}/"* "${ICONS_DIR}/"
        log_info "Copied icon themes"
        ;;
      sddm)
        exec_cmd sudo mkdir -p "${SDDM_DIR}"
        exec_cmd sudo cp -r "${src_path}/"* "${SDDM_DIR}/"
        log_info "Copied SDDM themes"
        ;;
      look-and-feel)
        exec_cmd mkdir -p "${LOOKANDFEEL_DIR}"
        exec_cmd cp -r "${src_path}/"* "${LOOKANDFEEL_DIR}/"
        log_info "Copied look-and-feel themes"
        ;;
    esac
  done

  exec_cmd rm -rf "${tmp_dir}"

  if command -v plasma-apply-desktoptheme &>/dev/null; then
    exec_cmd plasma-apply-desktoptheme "${theme_name}"
    log_info "Applied desktop theme: ${theme_name}"
  else
    log_warn "plasma-apply-desktoptheme not found, skipping theme application"
  fi

  if command -v plasma-apply-colorscheme &>/dev/null; then
    exec_cmd plasma-apply-colorscheme "${theme_name}"
    log_info "Applied color scheme: ${theme_name}"
  fi

  log_success "Theme installation complete"
}
