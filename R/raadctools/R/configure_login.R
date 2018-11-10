#' Title
#'
#' @return
configure_login <- function() {
  new_msg <- stringr::str_glue(
    "\n\nIt looks like this is your first time connecting to Synapse from this
machine. Let's store your credentials so that you won't need to enter
them in the future (unless you switch to a different machine).\n\n
    "
  )
  cat(crayon::bold(crayon::green(new_msg)))

  user_msg <- stringr::str_glue(
    "Your username should be the same as what you use to log into Synapse
with your Google credentials, for example:
  'adamsd42@gene.com' or 'smith.joe@roche.com'\n\n
    "
  )
  cat(user_msg)
  u <- readline(prompt = "Username: ")

  key_msg <- stringr::str_glue(
    "\n\nFor instructions on how to find your API key, refer to this page on
the RAAD Challenge Synapse project:
https://www.synapse.org/#!Synapse:syn16910051/wiki/584268\n\n
    "
  )
  cat(key_msg)
  k <- readline(prompt = "API key: ")

  synapser::synLogin(email = u, apiKey = k, rememberMe = TRUE)
}

