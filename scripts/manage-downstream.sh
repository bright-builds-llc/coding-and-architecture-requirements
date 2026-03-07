#!/usr/bin/env bash
set -euo pipefail

default_repo_slug="bright-builds-llc/coding-and-architecture-requirements"
default_ref="main"

managed_pairs=(
  "templates/AGENTS.md|AGENTS.md"
  "templates/CONTRIBUTING.md|CONTRIBUTING.md"
  "templates/pull_request_template.md|.github/pull_request_template.md"
)

overrides_source="templates/standards-overrides.md"
overrides_destination="standards-overrides.md"
tmp_dir=""
script_dir=""
local_source_root=""

cleanup() {
  if [[ -n "$tmp_dir" && -d "$tmp_dir" ]]; then
    rm -rf "$tmp_dir"
  fi
}

usage() {
  cat <<'EOF'
Usage: manage-downstream.sh <install|update|status|uninstall> [options]

Commands:
  install     Install the managed files into the target repository.
  update      Refresh the managed files from a newer or different ref.
  status      Show which managed files are present and the current pin.
  uninstall   Remove managed files. Keeps standards-overrides.md unless
              --remove-overrides is passed.

Options:
  --ref <git-ref>          Source ref to pin in AGENTS.md. Defaults to the
                           current pin for update, otherwise main.
  --repo <owner/repo>      Source GitHub repository. Defaults to the current
                           AGENTS.md source for update, otherwise
                           bright-builds-llc/coding-and-architecture-requirements.
  --repo-root <path>       Target repository root. Defaults to the current
                           directory.
  --force                  Overwrite existing managed files during install.
  --remove-overrides       Also delete standards-overrides.md during uninstall.
  -h, --help               Show this help text.
EOF
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

note() {
  printf '%s\n' "$*"
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

escape_sed_replacement() {
  printf '%s' "$1" | sed -e 's/[&|\\]/\\&/g'
}

extract_markdown_value() {
  local file_path="$1"
  local label="$2"

  awk -v label="$label" '
    BEGIN {
      prefix = "- " label ": `"
    }

    index($0, prefix) == 1 {
      value = substr($0, length(prefix) + 1)
      sub(/`$/, "", value)
      print value
      exit
    }
  ' "$file_path"
}

extract_repo_slug_from_url() {
  local repo_url="$1"

  printf '%s' "$repo_url" | sed -n 's#^https://github.com/\(.*\)$#\1#p' | sed 's#/$##'
}

download_file() {
  local source_path="$1"
  local output_path="$2"
  local maybe_local_source_path=""

  maybe_local_source_path="${local_source_root}/${source_path}"

  if [[ -n "$local_source_root" && -f "$maybe_local_source_path" ]]; then
    cp "$maybe_local_source_path" "$output_path"
    return
  fi

  require_command curl
  curl -fsSL "${raw_base}/${source_path}" -o "$output_path"
}

render_agents_template() {
  local source_path="$1"
  local output_path="$2"
  local repo_url_escaped=""
  local ref_escaped=""
  local standards_index_url_escaped=""

  repo_url_escaped="$(escape_sed_replacement "$repo_url")"
  ref_escaped="$(escape_sed_replacement "$ref")"
  standards_index_url_escaped="$(escape_sed_replacement "$standards_index_url")"

  sed \
    -e "s|REPLACE_WITH_REPO_URL|${repo_url_escaped}|g" \
    -e "s|REPLACE_WITH_TAG_OR_COMMIT|${ref_escaped}|g" \
    -e "s|REPLACE_WITH_TAGGED_STANDARDS_INDEX_URL|${standards_index_url_escaped}|g" \
    "$source_path" > "$output_path"
}

write_managed_file() {
  local source_path="$1"
  local relative_destination="$2"
  local destination_path="${repo_root}/${relative_destination}"
  local downloaded_path="${tmp_dir}/$(basename "$source_path")"

  download_file "$source_path" "$downloaded_path"
  mkdir -p "$(dirname "$destination_path")"

  if [[ "$relative_destination" == "AGENTS.md" ]]; then
    render_agents_template "$downloaded_path" "$destination_path"
  else
    cp "$downloaded_path" "$destination_path"
  fi

  note "Wrote ${relative_destination}"
}

install_or_update() {
  local pair=""

  tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/coding-reqs.XXXXXX")"

  for pair in "${managed_pairs[@]}"; do
    local source_path=""
    local relative_destination=""

    IFS='|' read -r source_path relative_destination <<< "$pair"
    write_managed_file "$source_path" "$relative_destination"
  done

  if [[ ! -f "${repo_root}/${overrides_destination}" ]]; then
    write_managed_file "$overrides_source" "$overrides_destination"
  else
    note "Kept existing ${overrides_destination}"
  fi
}

status() {
  local pair=""

  note "Target repository: ${repo_root}"

  for pair in "${managed_pairs[@]}"; do
    local source_path=""
    local relative_destination=""
    local destination_path=""

    IFS='|' read -r source_path relative_destination <<< "$pair"
    destination_path="${repo_root}/${relative_destination}"

    if [[ -f "$destination_path" ]]; then
      note "[present] ${relative_destination}"
    else
      note "[missing] ${relative_destination}"
    fi
  done

  if [[ -f "${repo_root}/${overrides_destination}" ]]; then
    note "[present] ${overrides_destination}"
  else
    note "[missing] ${overrides_destination}"
  fi

  if [[ -f "${repo_root}/AGENTS.md" ]]; then
    local current_source=""
    local current_ref=""

    current_source="$(extract_markdown_value "${repo_root}/AGENTS.md" "Standards repository")"
    current_ref="$(extract_markdown_value "${repo_root}/AGENTS.md" "Version pin")"

    if [[ -n "$current_source" ]]; then
      note "Pinned source: ${current_source}"
    fi

    if [[ -n "$current_ref" ]]; then
      note "Pinned ref: ${current_ref}"
    fi
  fi
}

uninstall() {
  local pair=""

  for pair in "${managed_pairs[@]}"; do
    local source_path=""
    local relative_destination=""
    local destination_path=""

    IFS='|' read -r source_path relative_destination <<< "$pair"
    destination_path="${repo_root}/${relative_destination}"

    if [[ -f "$destination_path" ]]; then
      rm -f "$destination_path"
      note "Removed ${relative_destination}"
    fi
  done

  if [[ "$remove_overrides" -eq 1 && -f "${repo_root}/${overrides_destination}" ]]; then
    rm -f "${repo_root}/${overrides_destination}"
    note "Removed ${overrides_destination}"
  fi

  rmdir "${repo_root}/.github" 2>/dev/null || true
}

trap cleanup EXIT

if script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"; then
  if [[ -f "${script_dir}/../templates/AGENTS.md" ]]; then
    local_source_root="$(cd "${script_dir}/.." && pwd)"
  fi
fi

command_name="${1:-}"

if [[ -z "$command_name" || "$command_name" == "-h" || "$command_name" == "--help" || "$command_name" == "help" ]]; then
  usage
  exit 0
fi

shift

repo_slug=""
ref=""
repo_root="$(pwd)"
force=0
remove_overrides=0
repo_was_explicit=0
ref_was_explicit=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ref)
      [[ $# -ge 2 ]] || die "missing value for --ref"
      ref="$2"
      ref_was_explicit=1
      shift 2
      ;;
    --repo)
      [[ $# -ge 2 ]] || die "missing value for --repo"
      repo_slug="$2"
      repo_was_explicit=1
      shift 2
      ;;
    --repo-root)
      [[ $# -ge 2 ]] || die "missing value for --repo-root"
      repo_root="$2"
      shift 2
      ;;
    --force)
      force=1
      shift
      ;;
    --remove-overrides)
      remove_overrides=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
done

[[ -d "$repo_root" ]] || die "repo root does not exist: $repo_root"
repo_root="$(cd "$repo_root" && pwd)"

agents_path="${repo_root}/AGENTS.md"

if [[ "$command_name" == "update" && -f "$agents_path" ]]; then
  current_source="$(extract_markdown_value "$agents_path" "Standards repository")"
  current_ref="$(extract_markdown_value "$agents_path" "Version pin")"

  if [[ "$repo_was_explicit" -eq 0 && -n "$current_source" ]]; then
    maybe_repo_slug="$(extract_repo_slug_from_url "$current_source")"

    if [[ -n "$maybe_repo_slug" ]]; then
      repo_slug="$maybe_repo_slug"
    fi
  fi

  if [[ "$ref_was_explicit" -eq 0 && -n "$current_ref" ]]; then
    ref="$current_ref"
  fi
fi

if [[ -z "$repo_slug" ]]; then
  repo_slug="$default_repo_slug"
fi

if [[ -z "$ref" ]]; then
  ref="$default_ref"
fi

repo_url="https://github.com/${repo_slug}"
raw_base="https://raw.githubusercontent.com/${repo_slug}/${ref}"
standards_index_url="${repo_url}/blob/${ref}/standards/index.md"

case "$command_name" in
  install)
    existing_managed_files=()

    for pair in "${managed_pairs[@]}"; do
      IFS='|' read -r source_path relative_destination <<< "$pair"
      if [[ -f "${repo_root}/${relative_destination}" ]]; then
        existing_managed_files+=("$relative_destination")
      fi
    done

    if [[ "${#existing_managed_files[@]}" -gt 0 && "$force" -ne 1 ]]; then
      die "managed files already exist: ${existing_managed_files[*]}. Re-run with --force or use update."
    fi

    install_or_update
    note "Pinned canonical standards to ${repo_url} @ ${ref}"
    ;;
  update)
    install_or_update
    note "Updated canonical standards pin to ${repo_url} @ ${ref}"
    ;;
  status)
    status
    ;;
  uninstall)
    uninstall
    ;;
  *)
    die "unknown command: ${command_name}"
    ;;
esac
