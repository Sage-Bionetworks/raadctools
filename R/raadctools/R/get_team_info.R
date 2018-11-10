#' Collect challenge team information for the specified Synapse user.
#'
#' @param owner_id
#'
#' @return
#' @export
#'
#' @examples
get_team_info <- function(owner_id) {
  team_df <- tryCatch(
    get_challenge_teams(),
    error = function(e) get_team_table()
  )

  owner_teams <- synapser::synRestGET(
    glue::glue("/user/{id}/team/id", id = owner_id)
  )
  owner_team_ids <- purrr::flatten_chr(owner_teams$teamIds)

  team_row <- team_df %>%
    dplyr::filter(team_id %in% owner_team_ids)
  team_id <- purrr::pluck(team_row, "team_id")
  team_project_id <- lookup_team_project(team_id)

  list(team_id = team_id,
       project_id = team_project_id)
}


#' Title
#'
#' @return
get_challenge_teams <- function() {
  challenge_ids <- c("4295", "4288")
  team_df <- challenge_ids %>%
    purrr::set_names(.) %>%
    purrr::map(function(challenge_id) {
      teams <- synapser::synRestGET(
        glue::glue("/challenge/{id}/challengeTeam", id = challenge_id)
      )
      purrr::map_chr(teams$results, "teamId")}) %>%
    purrr::keep(~ length(.) > 0) %>%
    tibble::as_tibble() %>%
    tidyr::gather(challenge_id, team_id)
}


#' Title
#'
#' @return
get_team_table <- function() {
  table_id <- "syn17007653"
  table_query <- glue::glue("SELECT * FROM {table}", table = table_id)
  res <- synapser::synTableQuery(table_query)
  dplyr::rename(res$asDataFrame(), team_id = teamId)
}


#' Look up the project/wiki ID for the specified challenge team.
#'
#' @param team_id
#'
#' @return
lookup_team_project <- function(team_id) {
  table_id <- "syn17007653"
  table_query <- glue::glue("SELECT * FROM {table} WHERE teamId = {id}",
                            table = table_id, id = team_id)
  res <- synapser::synTableQuery(table_query)
  purrr::pluck(res$asDataFrame(), "wikiSynId")
}
