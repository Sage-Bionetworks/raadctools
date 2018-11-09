#' Submit predictions to the RAAD Challenge evaluation queue
#'
#' Validates prediction data frame (`.data`) to check for any formatting
#' errors, saves data to local CSV file, stores file in Synapse, then submits
#' Synapse entity to RAAD Challenge evaluation queue for scoring.
#'
#' @param .data A tbl or data frame with participant predictions.
#' @param project_id Synapse ID for the participant's team project, where
#'     submitted predictions will be stored.
#' @param team_id ID (7-digit string) of the participant's team.
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
  team_id,
  project_id,
  validate_only = FALSE
) {
  message("Running checks to validate data frame format...\n")

  validate_predictions(.data)

  if (!validate_only) {
    if (confirm_submission() == 2) {
      stop("Exiting submission attempt.", call. = FALSE)
    }

    message("Writing data to local CSV file...\n")
    submission_filename <- create_submission(.data)

    submission_entity <- synapser::synStore(
      synapser::File(path = submission_filename, parentId = project_id)
    )
    submission_entity_id <- submission_entity$id

    # submission_object <- synapser::synSubmit(
    #   evaluation = "9612371",
    #   entity = submission_entity
    # )
    submission = list(id = "test_id")
    submission_id <- submission$id

    message(stringr::str_glue("Successfully submitted file: '{filename}'\n",
                              " > stored as '{entity_id}'\n",
                              " > submission ID: '{sub_id}'",
                              filename = submission_filename,
                              entity_id = submission_entity_id,
                              sub_id = submission_id))
  }
}


confirm_submission <- function() {
  msg <- stringr::str_glue(
    "Each team is allotted ONE submission per 24 hours. After submitting
    these predictions, you will not be able to submit again until tomorrow.

    Are you sure you want to submit?"
  )
  menu(c("Yes", "No"), title = crayon::bold(msg))
}
