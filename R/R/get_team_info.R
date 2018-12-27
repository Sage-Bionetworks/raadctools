#' Collect challenge team information for the specified Synapse user.
#'
#' @param owner_id Synapse user ID (integer string) of the participant.
#'
#' @return
#' @export
#'
#' @examples
get_team_info <- function(syn, owner_id) {
  # owner_teams <- synapser::synRestGET(
  #   glue::glue("/user/{id}/team/id", id = owner_id)
  # )
  # owner_team_ids <- purrr::flatten_chr(owner_teams$teamIds)
  owner_teams <- syn$restGET(
    glue::glue("/user/{id}/team/id", id = owner_id)
  )
  owner_team_ids <- owner_teams$teamIds
   
   
  # raad2_team <- owner_team_ids %>%
  #   purrr::set_names(.) %>%
  #   purrr::map(~ synapser::synGetTeam(.)[["name"]]) %>%
  #   purrr::discard(~ stringr::str_detect(., "(Participants|Admin)")) %>%
  #   purrr::keep(~ stringr::str_detect(., "RAAD2 "))
  raad2_team <- owner_team_ids %>%
    purrr::set_names(.) %>%
    purrr::map(~ syn$getTeam(.)[["name"]]) %>%
    purrr::discard(~ stringr::str_detect(., "(Participants|Admin)")) %>%
    purrr::keep(~ stringr::str_detect(., "RAAD2 "))
  
  # team_folder_id <- .lookup_prediction_folder(raad2_team[[1]])
  team_folder_id <- .lookup_prediction_folder(syn, raad2_team[[1]])
    
    list(team_id = names(raad2_team)[1],
         team_name = raad2_team[[1]],
         folder_id = team_folder_id)
}


#' Collect registered challenge team IDs via Synapse REST API.
#'
#' @return
.get_challenge_teams <- function(syn, challenge_id = "4288") {
  teams <- syn$restGET(
    glue::glue("/challenge/{id}/challengeTeam", id = challenge_id)
  )
  purrr::map_chr(teams$results, "teamId")
}


#' Look up folder ID where prediction file is to be stored.
#'
#' @param team_name Synapse team name.
#'
#' @return String with Synapse ID for submission folder.
.lookup_prediction_folder <- function(syn, team_name) {
  submission_folder <- "syn17097318"
  team_name <- stringr::str_replace(team_name, "^RAAD2 ", "")
  
  # folder_items <- synapser::synGetChildren(submission_folder)$asList()
  folder_items <- reticulate::iterate(syn$getChildren(submission_folder))
  
  prediction_folder <- purrr::keep(folder_items, ~ .$name == team_name)
  purrr::flatten(prediction_folder)$id
}
