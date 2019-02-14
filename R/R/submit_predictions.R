#' Submit predictions to the RAAD Challenge evaluation queue.
#'
#' Validates prediction data frame (`predictions`) to check for any formatting
#' errors, saves data to local CSV file, stores file in Synapse, then submits
#' Synapse entity to RAAD Challenge evaluation queue for scoring.
#'
#' @param predictions A dataframe/tibble with two columns, \emph{PatientID} and
#'     \emph{RespondingSubgroup}.
#' @param submitter_id Participant Synapse registered email. If not provided,
#'     user will be prompted for email before submission.
#' @param validate_only If `TRUE`, check data for any formatting errors but
#'     don't submit to the challenge.
#' @param skip_validation If `TRUE`, skip formatting checks and submit data
#'     to the challenge. For developers only!
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
#'   PatientID = submitRAADC2::patient_ids,
#'   RespondingSubgroup = rep(c("Tecentriq","Chemo"), 500)
#' )
#'
#' # Submitting predictions for user "synuser@gene.com"
#'
#' submit_predictions(d_predictions, submitter_id = "synuser@gene.com")
#'
#' # To validate data only but not submit:
#' submit_predictions(d_predictions, submitter_id = "synuser@gene.com",
#'                    validate_only = TRUE)
# 
#' # To simulate submission process without uploading or submitting data:
#' submit_predictions(d_predictions, submitter_id = "synuser@gene.com",
#'                    dry_run = TRUE)
#' }
submit_raadc2 <- function(
  predictions,
  submitter_id = NULL,
  validate_only = FALSE,
  skip_validation = FALSE,
  dry_run = FALSE,
  syn = NULL
) {
  suppressWarnings({
    
    if (!skip_validation) {
      cat(crayon::yellow(
        "\nRunning checks to validate data frame format...\n\n"
      ))
      valid <- validate_predictions(predictions)
      if(valid) {cat(crayon::green("All checks passed.\n"))}
    }
    
    if (!validate_only) {
      
      if (is.null(syn)) {
        syn <- .get_syn_client()
      }

      if (is.null(submitter_id) && is.null(syn$username)) {
        submitter_id <- .user_email_prompt()
      } else {
        submitter_id <- syn$username
      }
      
      tryCatch(
        msg <- capture.output(
          syn$getUserProfile()
        ),
        error = function(e) syn <- synapse_login(syn, submitter_id)
      )
      
      if (is.na(as.integer(submitter_id))) {
        owner_id <- .lookup_owner_id(syn)
      } else {
        owner_id <- submitter_id
      }
      
      team_info <- get_team_info(syn, owner_id)
      
      exit_msg <- function(final = FALSE) {
        if (final) {
          instructions <- glue::glue("Visit the RAAD2 Challenge page in Synapse ",
                                     "to track results in the leaderboard.")
        } else {
          instructions <- "Run `submit_raadc2()` to try again when ready."
        }
        glue::glue("\nExiting submission attempt.\n",
                   instructions)
      }
      cat(crayon::yellow("\n\nChecking ability to submit...\n\n"))
      is_eligible <- .check_eligibility(syn, team_info, owner_id)
      if (!is_eligible) {
        stop(exit_msg(final = TRUE), call. = FALSE)
      }
      
      if (.confirm_prompt() == 2) {
        stop(exit_msg(), call. = FALSE)
      }
      
      cat(crayon::yellow("\nWriting data to local CSV file...\n"))
      submission_filename <- .create_submission(predictions, dry_run = dry_run)
      
      if (!dry_run) {
        cat(crayon::yellow("\nUploading prediction file to Synapse...\n"))
        submission_entity <- .upload_predictions(
          syn,
          submission_filename,
          team_info
        )
        
        submission_entity_id <- submission_entity$id
        submission_entity_version <- submission_entity$versionNumber
        
        cat(crayon::yellow(
          "\nSubmitting prediction to challenge evaluation queue...\n"
        ))
        submission_object <- syn$submit(
          evaluation = "9614112",
          entity = submission_entity,
          team = team_info$team_name
        )
        submission_id <- submission_object$id
      } else {
        submission_entity_id <- "<pending; dry-run only>"
        submission_entity_version <- "TBD"
        submission_id <- "<pending; dry-run only>"
      }
      
      submit_msg <- glue::glue(
        "\n
      Successfully submitted file: '{filename}'
       > stored as '{entity_id}' [version: {version}]
       > submission ID: '{sub_id}'
      ",
        filename = submission_filename,
        entity_id = submission_entity_id,
        version = submission_entity_version,
        sub_id = submission_id
      )
      cat(submit_msg)
      
      cat(crayon::green(
        .success_msg(submission_filename, submission_entity_id, submission_id)
      ))
    }
  })
}


.confirm_prompt_text <- function() {
  glue::glue(
    "\n
    Each team is allotted a total of THREE valid submissions to the challenge. 
    You can submit anytime between February 19th and March 15th — it's up to
    you and your team to decide when to submit predictions within the open
    window. You will be able to see your score on the leaderboard only for your
    FIRST TWO submissions. Once your team has reached its quota, you will not 
    be able to submit again. 
    \nAre you sure you want to submit?
    "
  )
}


#' Prompt user to verify whether they want to submit to challenge.
#'
#' @return None
.confirm_prompt <- function() {
  msg <- .confirm_prompt_text()
  menu(c("Yes", "No"), title = crayon::bold(crayon::green(msg)))
}


#' Provide user with information about where to find submission results.
#'
#' @param filename
#' @param entity_id
#' @param sub_id
#'
#' @return
.success_msg <- function(filename, entity_id, sub_id) {
  glue::glue(
    "\n\n
    You can find the file with your predictions ('{fname}') on the RAAD2
    Challenge Synapse project at
    https://www.synapse.org/#!Synapse:{eid}
    \n\n",
    fname = filename,
    eid = entity_id
  )
}



