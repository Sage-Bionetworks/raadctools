#' Submit predictions to the RAAD Challenge evaluation queue.
#'
#' Validates prediction data frame (`predictions`) to check for any formatting
#' errors, saves data to local CSV file, stores file in Synapse, then submits
#' Synapse entity to RAAD Challenge evaluation queue for scoring.
#'
#' @param predictions A dataframe/tibble with two columns, \emph{PatientID} and
#'     \emph{RespondingSubgroup}.
#' @param submitter_id Participant Synapse ID or registered email.
#' @param validate_only If `TRUE`, check data for any formatting errors but
#'     don't submit to the challenge.
#' @param skip_validation If `TRUE`, skip formatting checks and submit data
#'     to the challenge.
#' @param dry_run If `TRUE`, execute submission steps, but don't store any
#'     data in Synapse.
#'
#' @return None
#' @export
#'
#' @examples
#' \dontrun{
#' # Example prediction data frame
#' set.seed(2018)
#' d_predictions <- data.frame(
#'   PatientID = paste0("Pat",1:400),
#'   RespondingSubgroup = rep(c("Tecentriq","Chemo"), 200)
#' )
#'
#' # Submitting predictions for team "1234567" and team project "syn16810564"
#'
#' submit_predictions(d_predictions, "1234567", "syn16810564")
#'
#' # To validate data only but not submit:
#' submit_predictions(d_predictions, "1234567", "syn16810564",
#'                    validate_only = TRUE)
#'}
submit_raadc2 <- function(
  predictions,
  submitter_id = NULL,
  validate_only = FALSE,
  skip_validation = FALSE,
  dry_run = FALSE
) {
  suppressWarnings({
  
  if (!skip_validation) {
    cat(crayon::yellow(
      "\nRunning checks to validate data frame format...\n\n"
    ))
    getRAADC2::validate_predictions(predictions)
  }
  
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
    cat(crayon::yellow("\nChecking ability to submit...\n\n"))
    is_eligible <- check_eligibility(team_info$team_id, owner_id)
    is_certified <- TRUE # check_certification(owner_id)
    if (!is_eligible | !is_certified) {
      switch_user("svc")
      stop("\nExiting submission attempt.", call. = FALSE)
    }
    
    if (confirm_submission() == 2) {
      switch_user("svc")
      stop("\nExiting submission attempt.", call. = FALSE)
    }
    
    cat(crayon::yellow("\nWriting data to local CSV file...\n"))
    print(dry_run)
    submission_filename <- create_submission(predictions, dry_run = dry_run)
    
    if (!dry_run) {
      switch_user("svc")
      cat(crayon::yellow("\nUploading prediction file to Synapse...\n\n"))
      submission_entity <- synapser::synStore(
        synapser::File(
          path = submission_filename,
          parentId = team_info$folder_id
        )
      )
      
      submission_entity_id <- submission_entity$id
      
      switch_user(submitter_id)
      cat(crayon::yellow(
        "\n\nSubmitting prediction to challenge evaluation queue...\n"
      ))
      submission_object <- synapser::synSubmit(
        evaluation = "9614112",
        entity = submission_entity,
        team = synapser::synGetTeam(team_info$team_id)
      )
      submission_entity_id <- submission_object$entityId
      submission_id <- submission_object$id
    } else {
      submission_entity_id <- "<pending; dry-run only>"
      submission_id <- "<pending; dry-run only>"
    }
    
    switch_user("svc")
    
    submit_msg <- glue::glue(
      "\n
      Successfully submitted file: '{filename}'
       > stored as '{entity_id}'
       > submission ID: '{sub_id}'
      ",
      filename = submission_filename,
      entity_id = submission_entity_id,
      sub_id = submission_id
    )
    cat(submit_msg)
    
    cat(crayon::green(
      success_msg(submission_filename, submission_entity_id, submission_id)
    ))
  }
  })
}


#' Prompt user to verify whether they want to submit to challenge.
#'
#' @return None
confirm_submission <- function() {
  msg <- glue::glue(
    "\n
    Each team is allotted ONE submission per 24 hours. After submitting
    these predictions, you will not be able to submit again until tomorrow.
    \nAre you sure you want to submit?
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
    "\n\n
    You can find the file with your predictions ('{fname}') on your team's
    Synapse project at
    https://www.synapse.org/#!Synapse:{eid}
    \n\n",
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
    synapser::synLogin(silent = TRUE)
  } else {
    synapser::synLogin(
      email = user,
      apiKey = Sys.getenv("SYN_API_KEY"),
      silent = TRUE
    )
  }
}

