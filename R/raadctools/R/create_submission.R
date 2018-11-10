#' Create submission file for RAAD Challenge
#'
#' Writes `.data` to CSV file named with user ID and time stamp.
#'
#' @param .data A tbl or data frame with participant predictions.
#'
#' @return `create_submission()` returns a string with the file name for the
#'     locally saved file.
create_submission <- function(.data, dry_run = FALSE) {
  suppressWarnings(
    time_stamp <- strftime(
      x = lubridate::now("UTC"),
      format = "%Y-%m-%d_%H-%M-%OS_%Z",
      tz = "UTC"
    )
  )
  submission_filename <- stringr::str_glue("{user}_{time}.csv",
                                           user = Sys.getenv("USER"),
                                           time = time_stamp)

  if (!dry_run) {
    readr::write_csv(.data, submission_filename)
  }
  submission_filename
}
