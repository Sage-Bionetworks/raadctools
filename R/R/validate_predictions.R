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
#' patient_nums <- stringr::str_pad(1:1000, width = 5, side = "left", pad = "0")
#' d_predictions <- data.frame(
#'   PatientID = stringr::str_c("RAADCV", patient_nums),
#'   Treatment = rep(c("Tecentriq","Chemo"), 500)
#' )
#'
#' validate_predictions(d_predictions)
#' }
validate_predictions <- function(predictions) {
  # colnames correct
  if (paste(colnames(predictions),collapse = ":") != c("PatientID:Treatment")) {
    stop("Prediction headers not of the format PatientID, Treatment")
  } 
  
  predictions$PatientID <- as.character(predictions$PatientID)
  # check patient IDs
  if (!all(stringr::str_detect(predictions$PatientID, "RAADCV[0-9]{4}[0-9]"))) {
    stop(glue::glue("Unexpected value in PatientID column: \n",
                    "IDs should in the format RAADCV00000 ",
                    "(RAADCV prefix with 5 digit holders)"))
  }

  patient_nums <- stringr::str_pad(1:1000, width = 5, side = "left", pad = "0")
  patient_ids <- stringr::str_c("RAADCV", patient_nums)
  if (!all(predictions$PatientID %in% patient_ids)) {
    print(setdiff(predictions$PatientID, patient_ids))
    stop(glue::glue("Unexpected value in PatientID column: \n",
                    "IDs should be in the range RAADCV00001..RAADCV01000"))
  }
  
  suppressWarnings(
    if (!all(unique(predictions$PatientID) == patient_ids)) {
      missing_ids <- dplyr::setdiff(patient_ids, predictions$PatientID)
      stop(glue::glue("Missing the following patient IDs:\n
                    {ids}\n",
                      "IDs should comprise all entries in the range ",
                      "RAADCV00001..RAADCV01000",
                      ids = stringr::str_c(missing_ids, collapse = ",")))
    }
  )
  
  # check values
  if (paste(sort(unique(predictions$Treatment)),collapse = ":") != c("Chemo:Tecentriq")) {
    stop("Prediction values should be converted to Chemo, Tecentriq")
  }
  
  # 20 to 80% in Tecentriq
  test_pro <- sum(predictions$Treatment == "Tecentriq") / nrow(predictions)
  if (test_pro < 0.2 | test_pro > 0.8) {
    stop("Proportion in subgroup is not between 20 and 80%")
  }
  
  return(TRUE)
}