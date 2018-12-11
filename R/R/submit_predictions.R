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
#' @param dry_run If `TRUE`, execute submission steps, but don't store any
#'     data in Synapse.
#'
#' @return None
#' @export
#'
#' @examples
#' \dontrun{
#' # Example prediction data frame
#' prediction_df <- data.frame(
#'     Subject = seq_len(100),
#'     SubPopulation = rep_len(c("Y", "N"), 50)
#' )
#'
#' # Submitting predictions for team "1234567" and team project "syn16810564"
#'
#' submit_predictions(prediction_df, "1234567", "syn16810564")
#'
#' # To validate data only but not submit:
#' submit_predictions(prediction_df, "1234567", "syn16810564",
#'                    validate_only = TRUE)
#'}
submit_predictions <- function(
  .data,
  submitter_id,
  validate_only = FALSE,
  dry_run = FALSE
) {
  message("Running checks to validate data frame format...\n")

  validate_predictions(.data)

  if (!validate_only) {
    switch_user("svc")
    
    if (is.na(as.integer(submitter_id))) {
      owner_id <- lookup_owner_id(submitter_id)
    } else {
      owner_id <- submitter_id
    }
    # synapser::synLogin()
    # user_profile <- synapser::synGetUserProfile()
    # user_profile <- jsonlite::fromJSON(user_profile$json())
    # owner_id <- user_profile$ownerId

    team_info <- get_team_info(owner_id)

    switch_user(submitter_id)
    message("\n\nChecking ability to submit...\n")
    is_eligible <- check_eligibility(team_info$team_id, owner_id)
    is_certified <- TRUE # check_certification(owner_id)
    if (!is_eligible | !is_certified) {
      stop("\nExiting submission attempt.", call. = FALSE)
    }

    if (confirm_submission() == 2) {
      stop("\nExiting submission attempt.", call. = FALSE)
    }

    message("\nWriting data to local CSV file...\n")
    submission_filename <- create_submission(.data, stamp = FALSE, dry_run)

    if (!dry_run) {
      switch_user("svc")
      message("\nUploading prediction file to Synapse...\n")
      submission_entity <- synapser::synStore(
        synapser::File(
          path = submission_filename,
          parentId = team_info$folder_id)
      )

      submission_entity_id <- submission_entity$id

      message("\nSubmitting prediction to challenge evaluation queue...\n")
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

    cat(crayon::green(crayon::bold(
      success_msg(submission_filename, submission_entity_id, submission_id)
    )))
  }
}


#' Prompt user to verify whether they want to submit to challenge.
#'
#' @return None
confirm_submission <- function() {
  msg <- glue::glue(
    "\n\nEach team is allotted ONE submission per 24 hours. After submitting
these predictions, yous will not be able to submit again until tomorrow.

Are you sure you want to submit?
    "
  )
  menu(c("Yes", "No"), title = crayon::bold(crayon::green(msg)))
}


#' Provide user with information about where to find submission results.
#'
#' @param filename
#' @param entity_id
#' @param sub_id
#'
#' @return
success_msg <- function(filename, entity_id, sub_id) {
  glue::glue(
    "You can find the file with your predictions ('{fname}') on your team's
    Synapse project at
    https://www.synapse.org/#!Synapse:{eid}",
  fname = filename,
  eid = entity_id
  )
}

#' Look up the owner ID for Synapse user.
#'
#' @param user_id registered email of the participant.
#'
#' @return String with Synapse ID for team project.
lookup_owner_id <- function(user_id, table_id = "syn17091891") {
  table_query <- glue::glue("SELECT * FROM {table} WHERE userEmail = '{id}'",
                            table = table_id, id = user_id)
  res <- invisible(synapser::synTableQuery(table_query))
  purrr::pluck(res$asDataFrame(), "userId")
}

switch_user <- function(user) {
  if (user == "svc") {
    synapser::synLogin()
  } else {
    synapser::synLogin(
      email = user,
      apiKey = Sys.getenv("SYN_API_KEY")
    )
  }
}

