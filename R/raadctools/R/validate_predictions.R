#' Check prediction data for formatting errors.
#'
#' Validates prediction data frame (`.data`) to check for any formatting
#' errors.
#'
#' @param .data A tbl or data frame with participant predictions.
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
#' validate_predictions(prediction_df)
validate_predictions <- function(.data) {
  check_results <- testthat::with_reporter(
    testthat::SummaryReporter,
    run_checks(.data)
  )
  if(check_results$failures$size() > 0) {
    stop("One or more validation errors encountered; see reasons above.")
  } else {
    message("All validation checks passed.\n")
  }
}


#' Define cases and expectations for formatting checks.
#'
#' @param .data A tbl or data frame with participant predictions.
#'
#' @return None
run_checks <- function(.data) {
  col_names <- c("Subject", "SubPopulation")
  testthat::test_that(
    glue::glue("prediction data frame must have columns [{c}]",
               c = stringr::str_c(col_names, collapse = ", ")),
    {testthat::expect_named(.data, col_names, ignore.order = TRUE)}
  )

  testthat::test_that(
    "'Subject' column must be ordered sequence of integers from 1 to N",
    {subject_col <- .data$Subject
     testthat::expect_equal(subject_col, seq_len(length(subject_col)))}
  )

  testthat::test_that(
    "'SubPopulation' column must only contain character values 'Y' or 'N'",
    {testthat::expect_true(all(.data$SubPopulation %in% c("Y", "N")))}
  )
}
