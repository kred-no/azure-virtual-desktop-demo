location = "West Europe"

flags = {
  user_access  = true
  autoscaler   = false
}

session_hosts = 1

host_pool {
  name = "Demo"
  max_sessions_allowed = 2
}

aad_users = []
remote_applications = []