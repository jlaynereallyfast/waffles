# == Name
#
# nginx.events
#
# === Description
#
# Manages events key/value settings in nginx.conf
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * key: The key. Required.
# * value: A value for the key. Required.
# * file: The file to store the settings in. Optional. Defaults to /etc/nginx/nginx.conf.
#
# === Example
#
# ```shell
# nginx.events --key worker_connections --value 768
# ```
#
function nginx.events {
  stdlib.subtitle "nginx.events"

  if ! stdlib.command_exists augtool ; then
    stdlib.error "Cannot find augtool."
    if [[ -n $WAFFLES_EXIT_ON_ERROR ]]; then
      exit 1
    else
      return 1
    fi
  fi

  # Resource Options
  local -A options
  stdlib.options.create_option state "present"
  stdlib.options.create_option key   "__required__"
  stdlib.options.create_option value "__required__"
  stdlib.options.create_option file
  stdlib.options.parse_options "$@"

  # Local Variables
  local _name="${options[key]}"
  local _dir="/etc/nginx/"
  local _file

  # Internal Resource Configuration
  if [[ -n ${options[file]} ]]; then
    _file="${options[file]}"
  else
    _file="${_dir}/nginx.conf"
  fi

  # Process the resource
  stdlib.resource.process "nginx.events" "$_name"
}

function nginx.events.read {
  local _result

  if [[ ! -f $_file ]]; then
    stdlib_current_state="absent"
    return
  fi

  # Check if the key exists and the value matches
  stdlib_current_state=$(augeas.get --lens Nginx --file "$_file" --path "/events/${options[key]}")
  if [[ $stdlib_current_state == "absent" ]]; then
    return
  fi

  _result=$(augeas.get --lens Nginx --file "$_file" --path "/events/${options[key]}[. = '${options[value]}']")
  if [[ $_result == "absent" ]]; then
    stdlib_current_state="update"
    return
  fi

  stdlib_current_state="present"
}

function nginx.events.create {
  stdlib.capture_error mkdir -p "$_dir"

  local -a _augeas_commands=()
  _augeas_commands+=("set /files$_file/events/${options[key]} '${options[value]}'")

  local _result=$(augeas.run --lens Nginx --file "$_file" "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error adding nginx.http $_name with augeas: $_result"
    return
  fi
}

function nginx.events.update {
  nginx.events.delete
  nginx.events.create
}

function nginx.events.delete {
  local -a _augeas_commands=()
  _augeas_commands+=("rm /files$_file/events/${options[key]}[. = '${options[value]}']")
  local _result=$(augeas.run --lens Nginx --file "$_file" "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error deleting nginx.events $_name with augeas: $_result"
    return
  fi
}
