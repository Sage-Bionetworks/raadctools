#' Check whether user is certified on Synapse.
#'
#' @param owner_id Synapse user ID (integer string) of the participant.
#'
#' @return If user is certified, return `TRUE`; else return `FALSE`.
check_certification <- function(owner_id) {
  status <- get_certification_status(owner_id)
  if (!status) {

    warning_msg <- crayon::red(crayon::bold(
      "\nYou don't appear to be a certified user on Synapse.\n\n"))
    cat(glue::glue(
      warning_msg,
      "In order to upload information to Synapse or submit to the challenge
you must be a Synapse Certified User. Visit this page to become a certified
user (or ask another member of your team to submit):
  https://www.synapse.org/#!Quiz:Certification\n\n"
    ))
  }
  status
}


#' Retrieve Synapse certification status for user.
#'
#' @param owner_id Synapse user ID (integer string) of the participant.
#'
#' @return If user is certified, return `TRUE`; else return `FALSE`.
get_certification_status <- function(owner_id) {
  request <- glue::glue("/user/{id}/certifiedUserPassingRecord",
                        id = owner_id)
  res <- list(passed = FALSE)
  try(res <- synapser::synRestGET(request), silent = TRUE)
  res$passed
}
