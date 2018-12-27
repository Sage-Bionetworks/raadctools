#' Validate RAADC 2.0 predictions
#'
#' \code{validate_predictions} takes a set of predictions and checks for any
#' formatting errors.
#'
#' @param predictions A dataframe/tibble with two columns, \emph{PatientID} and
#' \emph{RespondingSubgroup}.
#'
#' @param subset_patientids Vector of patientids, if you only want to include
#' specific patients in the scoring process. This is used to do the 20% scoring
#' for the leaderboard.
#' 
#' @return If all checks pass, return TRUE; otherwise, raise an error.
#' 
#' @examples
#'
#' paste("Validate example 1")
#' set.seed(2018)
#' d_predictions <- data.frame(
#'   PatientID = paste0("Pat",1:400),
#'   RespondingSubgroup = rep(c("Tecentriq","Chemo"), 200)
#' )
#'
#' validate_predictions(d_predictions)
#'
#' paste("Validate example 2")
#'
#' validate_predictions(
#'   getRAADC2::d_predictions_harbron
#' )
#'
validate_predictions <- function(predictions) {
  # colnames correct
  if(paste(colnames(predictions),collapse = ":") != c("PatientID:RespondingSubgroup")) stop(
    "Predictions not of the format PatientID,RespondingSubgroup"
  )
  
  # check values
  if (
    paste(sort(unique(predictions$RespondingSubgroup)),collapse = ":") != c("Chemo:Tecentriq")
  ) {stop("Predictions should be converted to Chemo, Tecentriq")}
  
  # 20 to 80% in Tecentriq
  test_pro <- sum(predictions$RespondingSubgroup == "Tecentriq") / nrow(predictions)
  if (test_pro < 0.2 | test_pro > 0.8) stop(
    "Proportion in subgroup is not between 20 and 80%"
  )
  
  return(TRUE)
}