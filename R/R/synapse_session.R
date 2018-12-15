synapse_login <- function(user) {
  tryCatch(
    msg <- capture.output(
      synapser::synLogin(
        email = user,
        silent = TRUE
      )
    ),
    error = function(e) configure_login(user)
  )
}

#' Collect and store Synapse login credentials.
#'
#' @return None
configure_login <- function(u) {
  new_msg <- glue::glue(
    "\n\nIt looks like this is your first time connecting to Synapse from this
machine. Let's store your credentials so that you won't need to enter
them in the future (unless you switch to a different machine).\n\n
    "
  )
  cat(crayon::bold(crayon::green(new_msg)))

  key_msg <- glue::glue(
    "\n\nFor instructions on how to find your API key, refer to this page on
the RAAD Challenge Synapse project:
https://www.synapse.org/#!Synapse:syn16910051/wiki/584268\n\n
    "
  )
  cat(key_msg)
  k <- readline(prompt = "API key: ")
  msg <- capture.output(
    synapser::synLogin(email = u, apiKey = k, rememberMe = TRUE)
  )
}

collect_user_email <- function() {
  user_msg <- glue::glue(
    "\n\n
    Enter your Synapse user email.

    Your username should be the same as what you use to log into Synapse
    with your Google credentials, for example:
    'adamsd42@gene.com' or 'smith.joe@roche.com'\n\n
    "
  )
  cat(user_msg)
  readline(prompt = "Username: ")
}

#' Look up the owner ID for Synapse user.
#'
#' @return String with Synapse ID for team project.
lookup_owner_id <- function() {
  # table_id <- "syn17091891"
  # table_query <- glue::glue("SELECT * FROM {table} WHERE userEmail = '{id}'",
  #                           table = table_id, id = user_id)
  # res <- invisible(synapser::synTableQuery(table_query))
  # purrr::pluck(res$asDataFrame(), "userId")
  user_profile <- synapser::synGetUserProfile()
  user_profile <- jsonlite::fromJSON(user_profile$json())
  user_profile$ownerId
}