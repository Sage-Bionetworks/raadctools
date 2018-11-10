#' Check whether user is certified on Synapse.
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
