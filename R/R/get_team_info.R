#' Collect challenge team information for the specified Synapse user.
#'
#' @param owner_id Synapse user ID (integer string) of the participant.
#'
#' @return
#' @export
#'
#' @examples
get_team_info <- function(syn, owner_id) {
  owner_teams <- syn$restGET(
    glue::glue("/user/{id}/team/id", id = owner_id)
  )
  owner_team_ids <- owner_teams$teamIds
   
  raad2_team <- owner_team_ids %>%
    purrr::set_names(.) %>%
    purrr::map(~ syn$getTeam(.)[["name"]]) %>%
    purrr::discard(~ stringr::str_detect(., "(Participants|Admin)")) %>%
    purrr::keep(~ stringr::str_detect(., "RAAD2 "))
  
  team_info <- .lookup_prediction_folder(syn, raad2_team[[1]])
    
  team_info[["team_id"]] = names(raad2_team)[1]
  team_info[["team_name"]] = raad2_team[[1]]
  return(team_info)
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
  team_table_id <- "syn17096669"
  team_name <- stringr::str_replace(team_name, "^RAAD2 ", "")
  query <- glue::glue("select folderId, advancedCompute from {id} ",
                      "where teamName = '{name}'",
                      id = team_table_id,
                      name = team_name)
  print(query)
  team_table <- syn$tableQuery(query)
  team_info <- team_table$asDataFrame() %>% 
    unlist() %>% 
    purrr::map(~ iterate(.)[[1]])
  adv_cpu_status <- reticulate::py_str(team_info$advancedCompute)
  team_info$advancedCompute <- adv_cpu_status == "True"
  return(team_info)
}
