# == Name
#
# rabbitmq.user
#
# === Description
#
# Manages RabbitMQ users
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * user: The username of the rabbitmq user. Required. namevar.
# * password: The password of the rabbitmq user.
# * admin: Make the user an admin. Default: false.
#
# === Example
#
# ```shell
# rabbitmq.user --user root --password password
# ```
#
function rabbitmq.user {
  stdlib.subtitle "rabbitmq.user"

  # Resource Options
  local -A options
  stdlib.options.create_option state    "present"
  stdlib.options.create_option user     "__required__"
  stdlib.options.create_option admin    "false"
  stdlib.options.create_option password
  stdlib.options.parse_options "$@"

  # Local Variables
  local _admin_status="false"

  # Process the resource
  stdlib.resource.process "rabbitmq.user" "${options[user]}"
}

function rabbitmq.user.read {

  rabbitmqctl -q list_users 2>/dev/null | grep -q ${options[user]}
  if [[ $? == 1 ]]; then
    stdlib_current_state="absent"
    return
  fi

  rabbitmqctl -q list_users 2>/dev/null | grep ${options[user]} | grep -q administrator
  if [[ $? == 0 ]]; then
    _admin_status="true"
  fi

  if [[ ${options[admin]} != $_admin_status ]]; then
    stdlib_current_state="update"
    return
  fi

  local _pw_fail="false"
  if [[ -n ${options[password]} ]]; then
    rabbitmqctl eval "rabbit_auth_backend_internal:check_user_login(<<\"${options[name]}\">>, [{password, <<\"${options[password]}\">>}])." 2>/dev/null
    if [[ $? == 1 ]]; then
      rabbitmqctl eval "rabbit_auth_backend_internal:user_login_authentication(<<\"${options[user]}\">>, [{password, <<\"${options[password]}\">>}])." 2>/dev/null
      if [[ $? == 1 ]]; then
        _pw_fail="true"
      fi
    fi

    if [[ $_pw_fail == "true" ]]; then
      stdlib_current_state="update"
      return
    fi
  fi

  stdlib_current_state="present"
}

function rabbitmq.user.create {
  stdlib.capture_error "rabbitmqctl add_user ${options[user]} ${options[password]}"

  if [[ ${options[admin]} == "true" ]]; then
    stdlib.capture_error "rabbitmqctl set_user_tags ${options[user]} administrator"
  fi
}

function rabbitmq.user.update {
  stdlib.capture_error "rabbitmqctl change_password ${options[user]} ${options[password]}"

  if [[ ${options[admin]} != $_admin_status ]]; then
    if [[ ${options[admin]} == "true" ]]; then
      stdlib.capture_error "rabbitmqctl set_user_tags ${options[user]} administrator"
    else
      # TODO: this doesn't account for other tags
      stdlib.capture_error "rabbitmqctl set_user_tags ${options[user]}"
    fi
  fi
}

function rabbitmq.user.delete {
  stdlib.capture_error "rabbitmqctl delete_user ${options[user]}"
}
