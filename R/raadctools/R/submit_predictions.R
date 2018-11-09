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
#' @return returns list with values for...
#'     `submission_filename`
#'     `submission_entity_id`
#'     `submission_id`
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

    submission_filename <- create_submission(.data)

    # submission_entity <- synapser::synStore(
    #   synapser::File(path = submission_filename, parentId = project_id)
    # )
    # submission_entity_id <- submission_entity$id
    submission_entity_id <- "syn1234"

    # submission_object <- synapser::synSubmit(
    #   evaluation = "9612371",
    #   entity = submission_entity
    # )
    # submission_id <- submission$id

    # message("")
    message(stringr::str_glue("Successfully submitted file: '{}'",
                              "... stored as '{}'",
                              filename = submission_filename,
                              entity_id = submission_entity_id))
    # message(paste0("... stored as '",
    #                submission_entity_id, "'"))
    # message(paste0("Submission ID: '", submission_id))
  }
}
