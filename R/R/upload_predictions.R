.upload_predictions <- function(submission_filename, team_info) {
  entity_info <- .fetch_submission_entity(team_info$folder_id,
                                          submission_filename)
  if (is.null(entity_info$version)) {
    target_version <- 1 
  } else {
    target_version <- entity_info$version + 1
  }
  
  submission_entity <- synapser::synStore(
    synapser::File(
      path = submission_filename,
      parentId = team_info$folder_id
    )
  )
  entity_staged <- .monitor_submission_entity(
    team_info$folder_id,
    submission_filename,
    target_version
  )
  if (entity_staged) {
    entity_info <- .fetch_submission_entity(team_info$folder_id,
                                            submission_filename)
    return(entity_info)
  }
}


.fetch_submission_entity <- function(folder_id, submission_filename) {
  folder_items <- synapser::synGetChildren(folder_id)$asList()
  submission_entity <- purrr::keep(
    folder_items, 
    ~ .$name == submission_filename
  )
  list(id = purrr::flatten(submission_entity)$id,
       version = purrr::flatten(submission_entity)$versionNumber)
}


.monitor_submission_entity <- function(
  folder_id, 
  submission_filename, 
  target_version
) {
  version_match <- FALSE
  while (!version_match) {
    message("Checking entity status...")
    entity_info <- .fetch_submission_entity(folder_id, submission_filename)
    if (is.null(entity_info$version)) { entity_info$version <- 0 }
    version_match <- entity_info$version == target_version
  }
  message("Updated.")
  return(version_match)
}