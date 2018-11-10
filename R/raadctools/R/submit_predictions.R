#' Submit predictions to the RAAD Challenge evaluation queue.
#'
#' Validates prediction data frame (`.data`) to check for any formatting
#' errors, saves data to local CSV file, stores file in Synapse, then submits
#' Synapse entity to RAAD Challenge evaluation queue for scoring.
#'
#' @param .data A tbl or data frame with participant predictions.
#' @param project_id Synapse ID for the participant's team project, where
#'     submitted predictions will be stored.
#' @param validate_only If `TRUE`, check data for any formatting errors but
#'     don't submit to the challenge.
#'
#' @return None
#' @export
#'
#' @examples
#' # Example prediction data frame
#' prediction_df <- data.frame(
#'     Subject = seq_len(100),
#'     SubPopulation = rep_len(c("Y", "N"), 50)
#' )
#'
#' # Submitting predictions for team "1234567" and team project "syn16810564"
#' submit_predictions(prediction_df, "1234567", "syn16810564")
#'
#' # To validate data only but not submit:
#' submit_predictions(prediction_df, "1234567", "syn16810564",
#'                    validate_only = TRUE)
submit_predictions <- function(
  .data,
  validate_only = FALSE,
  dry_run = FALSE
) {
  message("Running checks to validate data frame format...\n")

  validate_predictions(.data)

  if (!validate_only) {
    # tryCatch(
    #   synapser::synLogin(),
    #   error = function(e) configure_login()
    # )
    synapser::synLogin()
    user_profile <- synapser::synGetUserProfile()
    user_profile <- jsonlite::fromJSON(user_profile$json())
    owner_id <- user_profile$ownerId
    team_info <- get_team_info(owner_id)

    message("\n\nChecking ability to submit...\n")
    check_eligibility(team_info$team_id, owner_id)

    if (confirm_submission() == 2) {
      stop("Exiting submission attempt.", call. = FALSE)
    }

    message("\nWriting data to local CSV file...\n")
    submission_filename <- create_submission(.data, dry_run)

    if (!dry_run) {
      submission_entity <- synapser::synStore(
        synapser::File(
          path = submission_filename,
          parentId = team_info$project_id)
      )
      submission_entity_id <- submission_entity$id

      submission_object <- synapser::synSubmit(
        eval_id = "9614112",
        entity = submission_entity
      )
    } else {
      submission_entity_id <- "<pending; dry-run only>"
      submission_id <- "<pending; dry-run only>"
    }

    submit_msg <- glue::glue(
      "
      Successfully submitted file: '{filename}'
       > stored as '{entity_id}'
       > submission ID: '{sub_id}'

      ",
      filename = submission_filename,
      entity_id = submission_entity_id,
      sub_id = submission_id
    )
    message(submit_msg)
  }
}


#' Prompt user to verify whether they want to submit to challenge.
#'
#' @return
confirm_submission <- function() {
  msg <- glue::glue(
    "\n\nEach team is allotted ONE submission per 24 hours. After submitting
these predictions, yous will not be able to submit again until tomorrow.

Are you sure you want to submit?
    "
  )
  menu(c("Yes", "No"), title = crayon::bold(msg))
}
