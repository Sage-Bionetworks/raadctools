#' Check whether user is eligible to submit to the challenge.
#'
#' @param team_id ID (integer string) of the participant's team.
#' @param owner_id Synapse user ID (integer string) of the participant.
#'
#' @return If eligible to submit, return `TRUE`; else return `FALSE`.
.check_eligibility <- function(syn, team_info, owner_id) {

  eligibility_data <- .get_eligibility_data(syn, team_info$team_id)

  team_eligibility <- .get_team_eligibility(eligibility_data)

  owner_eligibility <- .get_owner_eligibility(eligibility_data, owner_id)

  cat(glue::glue(
    crayon::bold(" > Team: ") %+% "{team_msg}\n\n",
    team_msg = glue::glue(.team_eligibility_msg(team_eligibility),
                          name = team_info$team_name)
  ))
  if (team_eligibility$isEligible) {
    cat(glue::glue(
      crayon::bold(" > User: ") %+% "{owner_msg}\n\n",
      owner_msg = .owner_eligibility_msg(owner_eligibility)
    ))
  }

  team_eligibility$isEligible & owner_eligibility$isEligible
}


#' Collect eligibility data for a team and its members.
#'
#' @param team_id ID (integer string) of the participant's team.
.get_eligibility_data <- function(syn, team_id) {
  eval_id <- "9614112"
  tryCatch(
    syn$restGET(
      glue::glue('/evaluation/{evalId}/team/{id}/submissionEligibility',
                 evalId = eval_id, id = team_id)
    ),
    error = function(e) {
      msg <- glue::glue("The RAAD2 Challenge submission queues are not ",
                        "currently open. Teams can submit between February ",
                        "14th and March 15th.")
      stop(msg, call. = FALSE)
    }
  )
}


#' Parse eligibility data to check overall team elibility.
.get_team_eligibility <- function(eligibility_data) {
  tibble::as_tibble(eligibility_data$teamEligibility)
}


#' Parse eligibility data to check participant elibility.
.get_owner_eligibility <- function(eligibility_data, owner_id) {
  eligibility_data$membersEligibility %>%
    purrr::map_df(tibble::as_tibble) %>%
    dplyr::filter(principalId == owner_id)
}


#' Construct message summarizing team submission eligibility.
#'
#' @param .data A tbl with eligibility status for submission team.
#'
#' @return String summarizing eligibility status and any reasons that team
#'     might currently be ineligible to submit.
.team_eligibility_msg <- function(.data) {
  .data %>%
    dplyr::mutate(
      eligible_msg = dplyr::if_else(
        isEligible,
        "Your team, {name}, is eligible to submit.",
        "Your team, {name}, is not eligible to submit at this time."
      ),
      quota_msg = dplyr::if_else(
        !isEligible & isQuotaFilled,
        "The team has filled its quota of 2 submissions for the challenge.",
        ""
      ),
      registered_msg = dplyr::if_else(
        !isEligible & !isRegistered,
        "The team is not registered for the challenge.",
        ""
      )
    ) %>%
    dplyr::select(dplyr::matches(".*_msg")) %>%
    purrr::flatten_chr() %>%
    stringr::str_c(collapse = " ")
}


#' Construct message summarizing user submission eligibility.
#'
#' @param .data A tbl with eligibility status for submitting user.
#'
#' @return String summarizing eligibility status and any reasons that user
#'     might currently be ineligible to submit.
.owner_eligibility_msg <- function(.data) {
  .data %>%
    dplyr::mutate(
      eligible_msg = dplyr::if_else(
        isEligible,
        "You're eligible to submit for your team.",
        "You're not currently eligible to submit. "
      ),
      registered_msg = dplyr::if_else(
        !isEligible & !isRegistered,
        unclass(glue::glue("You have not yet agreed to terms for the challenge. ",
                   "Please view the 'How to Participate' page on the RAAD2 ",
                   "Challenge wiki in Synapse.")),
        ""
      ),
      conflict_msg = dplyr::if_else(
        !isEligible & hasConflictingSubmission,
        "It appears you've submitted for a different challenge team.",
        ""
      )
    ) %>%
    dplyr::select(dplyr::matches(".*_msg")) %>%
    purrr::flatten_chr() %>%
    stringr::str_c(collapse = "")
}
