.upload_predictions <- function(syn, submission_filename, team_info) {
  entity_info <- .fetch_submission_entity(syn,
                                          team_info$folder_id,
                                          submission_filename)
  if (is.null(entity_info$version)) {
    target_version <- 1 
  } else {
    target_version <- entity_info$version + 1
  }
  
  submission_entity <- .stage_predictions(team_info$folder_id,
                                          submission_filename)
  return(list(id = submission_entity$entity_id,
              version = submission_entity$entity_version))
}


.stage_predictions <- function(folder_id, submission_filename) {
  prediction_data <- openssl::base64_encode(
    readr::read_file(submission_filename)
  )
  res <- httr::POST(
    url = "https://gja3h20usl.execute-api.us-east-1.amazonaws.com/v1/predictions",
    body = list(submission_folder = folder_id,
                data = prediction_data),
    encode = "json"
  )
  return(httr::content(res))
}


.fetch_submission_entity <- function(syn, folder_id, submission_filename) {
  folder_items <- reticulate::iterate(syn$getChildren(folder_id))
  submission_entity <- purrr::keep(
    folder_items, 
    ~ .$name == submission_filename
  )
  list(id = purrr::flatten(submission_entity)$id,
       version = purrr::flatten(submission_entity)$versionNumber)
}
