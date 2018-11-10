#' Title
#'
#' @param team_id
#' @param owner_id
#'
#' @return
check_eligibility <- function(team_id, owner_id) {
  team_name <- synapser::synGetTeam(team_id)[["name"]]
  eval_id <- "9614112"
  eligibility_data <- synapser::synRestGET(
    stringr::str_glue('/evaluation/{evalId}/team/{id}/submissionEligibility',
                      evalId = eval_id, id = team_id)
    )

  team_eligibility <- tibble::as_tibble(eligibility_data$teamEligibility)

  owner_eligibility <- eligibility_data$membersEligibility %>%
    purrr::map_df(tibble::as_tibble) %>%
    dplyr::filter(principalId == owner_id)

  cat(stringr::str_glue(
    crayon::bold(" > Team: ") %+% "{team_msg}\n\n",
    team_msg = stringr::str_glue(team_eligibility_msg(team_eligibility),
                                 name = team_name)
  ))
  if (team_eligibility$isEligible) {
    cat(stringr::str_glue(
      crayon::bold(" > User: ") %+% "{owner_msg}\n\n",
      owner_msg = owner_eligibility_msg(owner_eligibility)
    ))
  }

  team_eligibility$isEligible & owner_eligibility$isEligible
}

#' Title
#'
#' @param .data
#'
#' @return
team_eligibility_msg <- function(.data) {
  .data %>%
    mutate(
      eligible_msg = if_else(
        isEligible,
        "Your team, {name}, is eligible to submit.",
        "Your team, {name}, is not eligible to submit at this time."
      ),
      quota_msg = if_else(
        !isEligible & isQuotaFilled,
        "The team has reached its submission quota for this 24 hour period.",
        ""
      ),
      registered_msg = if_else(
        !isEligible & !isRegistered,
        "The team is not registered for the challenge.",
        ""
      )
    ) %>%
    dplyr::select(dplyr::matches(".*_msg")) %>%
    purrr::flatten_chr() %>%
    stringr::str_c(collapse = "")
}


#' Title
#'
#' @param .data
#'
#' @return
owner_eligibility_msg <- function(.data) {
  .data %>%
    mutate(
      eligible_msg = if_else(
        isEligible,
        "You're eligible to submit for your team.",
        "You're not currently eligible to submit."
      ),
      registered_msg = if_else(
        !isEligible & !isRegistered,
        "The team is not registered for the challenge.",
        ""
      ),
      conflict_msg = if_else(
        !isEligible & hasConflictingSubmission,
        "It appears you've submitted for a different challenge team.",
        ""
      )
    ) %>%
    dplyr::select(dplyr::matches(".*_msg")) %>%
    purrr::flatten_chr() %>%
    stringr::str_c(collapse = "")
}
