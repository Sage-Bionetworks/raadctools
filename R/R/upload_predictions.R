.upload_predictions <- function(syn, submission_filename, team_info) {
  submission_entity <- .stage_predictions(team_info$folder_id,
                                          submission_filename)
  return(submission_entity)
}


.stage_predictions <- function(folder_id, submission_filename, direct = FALSE) {
  if (direct) {
    synapseclient <- reticulate::import("synapseclient")
    syn_temp <- synapseclient$Synapse()
    syn_temp$login(
      email = Sys.getenv("EMAIL"),
      apiKey = Sys.getenv("API_KEY")
    )
    submission_entity <- syn_temp$store(
      synapseclient$File(
        path = submission_filename,
        parent = folder_id
      )
    )
    return(submission_entity)
  }
  prediction_data <- openssl::base64_encode(
    readr::read_file(submission_filename)
  )
  res <- httr::POST(
    url = "https://gja3h20usl.execute-api.us-east-1.amazonaws.com/v1/predictions",
    body = list(submission_folder = folder_id,
                data = prediction_data),
    encode = "json"
  )
  print(httr::content(res))
  return(httr::content(res))
}

