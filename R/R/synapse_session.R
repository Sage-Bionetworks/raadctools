#' Convenience wrapper function for Synapse login.
#'
#' @return None
synapse_login <- function(syn, user) {
  tryCatch(
    syn$login(email = Sys.getenv(paste(user, "SYN_EMAIL", sep = "_")),
              apiKey = Sys.getenv(paste(user, "SYN_API_KEY", sep = "_"))),
    error = function(e) syn <- .new_login(syn, user)
  )
  return(syn)
}


#' Clear any cached Synapse credentials without starting a new R session.
#'
#' @return None
clear_credentials <- function() {
  env_keys <- Sys.getenv() %>% 
    names() %>% 
    purrr::keep(~ stringr::str_detect(., "_(SYN_EMAIL|SYN_API_KEY)"))
  Sys.unsetenv(env_keys)
}


.get_syn_client <- function() {
  synapseclient <- reticulate::import("synapseclient")
  synapseclient$Synapse()
}

.user_email_prompt_text <- function() {
  glue::glue(
    "\n\nEnter your Synapse user email.
    
Your username should be the same as what you use to log into Synapse
with your Google credentials, for example:
'adamsd42@gene.com' or 'smith.joe@roche.com'\n\n
    "
  )
}

.api_key_prompt_text <- function() {
  glue::glue(
    "\nTo find your API key:

    1. Log into www.synapse.org
    2. Click on your profile in the upper right of the page; see the Synapse
       docs on User Profiles for more details: 
       https://docs.synapse.org/articles/user_profiles.html
    3. Click on 'Settings' tab
    4. Click 'Show API key' at the bottom of the page; you can copy and paste
       the key directly into your console.\n\n
    "
  )
}


.new_login_text <- function() {
  glue::glue(
    "\n\nIt looks like this is your first time connecting to Synapse during
this R session. Let's store your credentials so that you won't need to
enter them again (during this session).\n\n
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
  args <- purrr::set_names(list(u, k),
                           paste(u, c("SYN_EMAIL", "SYN_API_KEY"), sep = "_"))
  do.call(Sys.setenv, args)
  tryCatch(
    syn$login(email = Sys.getenv(paste(u, "SYN_EMAIL", sep = "_")),
              apiKey = Sys.getenv(paste(u, "SYN_API_KEY", sep = "_"))),
    error = function(e) {
      msg <- glue::glue("Something went wrong with the attempt to log you ",
                        "into Synapse. Please doublecheck your email and API ",
                        "key combination.")
      stop(msg, call. = FALSE)
    }
  )
  return(syn)
}


#' Look up the owner ID for Synapse user.
#'
#' @return String with Synapse ID for team project.
.lookup_owner_id <- function(syn) {
  user_profile <- syn$getUserProfile()
  user_profile$ownerId
}