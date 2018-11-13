#' Create submission file for RAAD Challenge.
#'
#' Writes `.data` to CSV file named with user ID and time stamp.
#'
#' @param .data A tbl or data frame with participant predictions.
#' @param stamp If `TRUE`, name the file according to user and time; otherwise
#'     use simple 'predictions.csv' file name.
#' @param dry_run If `TRUE`, return file name but don't create file.
#'
#' @return `create_submission()` returns a string with the file name for the
#'     locally saved file.
create_submission <- function(.data, stamp = FALSE, dry_run = FALSE) {
  if (stamp) {
    suppressWarnings(
      time_stamp <- strftime(
        x = lubridate::now("UTC"),
        format = "%Y-%m-%d_%H-%M-%OS_%Z",
        tz = "UTC"
      )
    )
    submission_filename <- glue::glue("{user}_{time}.csv",
                                      user = Sys.getenv("USER"),
                                      time = time_stamp)
  } else {
    submission_filename <- "prediction.csv"
  }

  if (!dry_run) {
    readr::write_csv(.data, submission_filename)
  }
  submission_filename
}
