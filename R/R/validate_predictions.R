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
#' \dontrun{
#' set.seed(2018)
#' d_predictions <- data.frame(
#'   PatientID = submitRAADC2::patient_ids,
#'   RespondingSubgroup = rep(c("Tecentriq","Chemo"), 500)
#' )
#'
#' validate_predictions(d_predictions)
#' }
validate_predictions <- function(predictions) {
  # colnames correct
  if (paste(colnames(predictions),collapse = ":") != c("PatientID:RespondingSubgroup")) {
    stop("Prediction headers not of the format PatientID, RespondingSubgroup")
  } 
  
  predictions$PatientID <- as.character(predictions$PatientID)
  # check patient IDs
  if (!all(stringr::str_detect(predictions$PatientID, "RAADCV[0-9]{4}[0-9]"))) {
    stop(glue::glue("Unexpected value in PatientID column: \n",
                    "IDs should in the format RAADCV00000 ",
                    "(RAADCV prefix with 5 digit holders)"))
  }

  no_extra <- all(predictions$PatientID %in% submitRAADC2::patient_ids)
  if (!no_extra) {
    extra_ids <- dplyr::setdiff(predictions$PatientID, 
                                submitRAADC2::patient_ids)
    stop(glue::glue(
        "
        Unexpected ID(s) in PatientID column:\n
          {ids}\n
        IDs for predictions should only match PatientID values 
        from the provided test data
        ",
        ids = stringr::str_c(extra_ids, collapse = ",")))
  }
  
  suppressWarnings(
    no_missing <- magrittr::equals(
      length(setdiff(submitRAADC2::patient_ids, predictions$PatientID)),
      0
    )
  )
  if (!no_missing) {
    missing_ids <- dplyr::setdiff(submitRAADC2::patient_ids, 
                                  predictions$PatientID)
    stop(glue::glue(
      "
        Missing the following patient ID(s):\n
        {ids}\n
        IDs for predictions should match all PatientID values 
        from the provided test data
        ",
      ids = stringr::str_c(missing_ids, collapse = ",")))
  }
  
  # check values
  if (paste(sort(unique(predictions$RespondingSubgroup)),collapse = ":") != c("Chemo:Tecentriq")) {
    stop("Prediction values should be converted to Chemo, Tecentriq")
  }
  
  # 20 to 80% in Tecentriq
  test_pro <- sum(predictions$RespondingSubgroup == "Tecentriq") / nrow(predictions)
  if (test_pro < 0.2 | test_pro > 0.8) {
    stop("Proportion in subgroup is not between 20 and 80%")
  }
  
  return(TRUE)
}