#' Convenience wrapper function for Synapse login.
#'
#' @return None
synapse_login <- function(syn, user) {
  sys_user <- Sys.info()[["user"]]
  tryCatch(
    syn$login(email = Sys.getenv(paste(sys_user, "EMAIL", sep = "_")),
              apiKey = Sys.getenv(paste(sys_user, "API_KEY", sep = "_"))),
    error = function(e) .new_login(syn, user)
  )
}

.get_syn_client <- function() {
  synapseclient <- reticulate::import("synapseclient")
  synapseclient$Synapse()
}

.user_email_prompt_text <- function() {
  glue::glue(
    "\n\n
    Enter your Synapse user email.
    
    Your username should be the same as what you use to log into Synapse
    with your Google credentials, for example:
    'adamsd42@gene.com' or 'smith.joe@roche.com'\n\n
    "
  )
}

.api_key_prompt_text <- function() {
  glue::glue(
    "\n\nFor instructions on how to find your API key, refer to this page on
    the RAAD Challenge Synapse project:
    https://www.synapse.org/#!Synapse:syn16910051/wiki/584268\n\n
    "
  )
}


.new_login_text <- function() {
  glue::glue(
    "\n\nIt looks like this is your first time connecting to Synapse from this
    machine. Let's store your credentials so that you won't need to enter
    them in the future (unless you switch to a different machine).\n\n
    "
  )
}


#' Collect and store registered Synapse email.
#'
#' @return String with user's email address.
.user_email_prompt <- function() {
  user_msg <- .user_email_prompt_text()
  cat(user_msg)
  readline(prompt = "Username: ")
}


#' Collect and store Synapse API key.
#'
#' @return String with user's API key.
.api_key_prompt <- function() {
  key_msg <- .api_key_prompt_text()
  cat(key_msg)
  readline(prompt = "API key: ")
}


#' Guide user through Synapse login steps.
#'
#' @return None
.new_login <- function(syn, u) {
  new_msg <- .new_login_text()
  cat(crayon::bold(crayon::green(new_msg)))

  k <- .api_key_prompt()
  sys_user <- Sys.info()[["user"]]
  args <- purrr::set_names(list(u, k),
                           paste(sys_user, c("EMAIL", "API_KEY"), sep = "_"))
  do.call(Sys.setenv, args)
  syn$login(email = Sys.getenv(paste(sys_user, "EMAIL", sep = "_")),
            apiKey = Sys.getenv(paste(sys_user, "API_KEY", sep = "_")))
}


#' Look up the owner ID for Synapse user.
#'
#' @return String with Synapse ID for team project.
.lookup_owner_id <- function(syn) {
  user_profile <- syn$getUserProfile()
  user_profile$ownerId
}