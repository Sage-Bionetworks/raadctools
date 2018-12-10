#' Collect challenge team information for the specified Synapse user.
#'
#' @param owner_id Synapse user ID (integer string) of the participant.
#'
#' @return
#' @export
#'
#' @examples
get_team_info <- function(owner_id) {
  team_df <- get_team_table()

  owner_teams <- synapser::synRestGET(
    glue::glue("/user/{id}/team/id", id = owner_id)
  )
  owner_team_ids <- purrr::flatten_chr(owner_teams$teamIds)

  team_row <- team_df %>%
    dplyr::filter(team_id %in% owner_team_ids)
  team_id <- purrr::pluck(team_row, "team_id")
  team_project_id <- lookup_team_project(team_id)
  team_folder_id <- lookup_prediction_folder(team_project_id)

  list(team_id = team_id,
       project_id = team_project_id,
       folder_id = team_folder_id)
}


#' Collect registered challenge team IDs via Synapse REST API.
#'
#' @return
get_challenge_teams <- function(challenge_id = "4288") {
  teams <- synapser::synRestGET(
    glue::glue("/challenge/{id}/challengeTeam", id = challenge_id)
  )
  purrr::map_chr(teams$results, "teamId")
}


#' Collect registered challenge team IDs from Synapse table.
#'
#' @return
get_team_table <- function(table_id = "syn17091912") {
  table_query <- glue::glue("SELECT * FROM {table}", table = table_id)
  res <- synapser::synTableQuery(table_query)
  dplyr::rename(res$asDataFrame(), team_id = teamId)
}


#' Look up the project/wiki ID for the specified challenge team.
#'
#' @param team_id ID (integer string) of the participant's team.
#'
#' @return String with Synapse ID for team project.
lookup_team_project <- function(team_id, table_id = "syn17091912") {
  table_query <- glue::glue("SELECT * FROM {table} WHERE teamId = {id}",
                            table = table_id, id = team_id)
  res <- invisible(synapser::synTableQuery(table_query))
  purrr::pluck(res$asDataFrame(), "projectId")
}


#' Look up folder ID where prediction file is to be stored.
#'
#' @param project_id Synapse ID of team's submission project.
#'
#' @return String with Synapse ID for submission folder.
lookup_prediction_folder <- function(project_id) {
  project_items <- synapser::synGetChildren(project_id)$asList()
  prediction_folder <- purrr::keep(project_items, ~ .$name == "Prediction File")
  purrr::flatten(prediction_folder)$id
}
