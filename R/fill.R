#' Fill in missing values with previous or next value
#'
#' @description
#' Fills missing values in the selected columns using the next or previous entry. Can be done by group.
#'
#' @param .data A data.frame or data.table
#' @param ... A selection of bare columns
#' @param .direction Direction in which to fill missing values. Currently "down" (the default), "up", "downup" (first down then up), or "updown" (first up and then down)
#' @param by Whether the filling should be done by group. Passed in a `list()`
#'
#' @return A data.table
#' @export
#' @md
#'
#' @examples
#' test_df <- data.table(x = c(NA, NA, NA, 4:10),
#'                       y = c(1:6, NA, 8, NA, 10),
#'                       z = c(rep("a", 8), rep("b", 2)))
#'
#' test_df %>%
#'   new_fill(x, y, by = z, .direction = "downup")
dt_fill <- function(.data, ..., .direction = c("down", "up", "downup", "updown"), by = NULL) {
  if (!is.data.frame(.data)) stop(".data must be a data.frame or data.table")
  if (!is.data.table(.data)) .data <- as.data.table(.data)

  by <- enexpr(by)

  if (length(.direction) > 1) .direction <- "down"

  if (.direction == "down") {
    filldown(.data, ..., by = !!by)
  } else if (.direction == "up") {
    fillup(.data, ..., by = !!by)
  } else if (.direction == "downup") {
    .data %>%
      filldown(..., by = !!by) %>%
      fillup(..., by = !!by)
  } else {
    .data %>%
      fillup(..., by = !!by) %>%
      filldown(..., by = !!by)
  }
}

filldown <- function(.data, ..., by = NULL) {
  if (!is.data.frame(.data)) stop(".data must be a data.frame or data.table")
  if (!is.data.table(.data)) .data <- as.data.table(.data)

  dots <- enexprs(...)
  by <- enexpr(by)

  for (dot in dots) {
    dot_type <- .data %>% dt_pull(!!dot) %>% class()

    if (dot_type %in% c("integer", "double", "numeric")) {
      .data %>%
        dt_mutate(!!dot := nafill(!!dot, type = "locf"), by = !!by)
    } else if (dot_type %in% c("character", "logical", "factor")) {
      eval_tidy(expr(
        .data[, ':='(na_index = 1:.N), by = !!by] %>%
          dt_mutate(na_index = fifelse(is.na(!!dot), NA_integer_, na_index)) %>%
          dt_mutate(na_index = nafill(na_index, type = "locf"), by = !!by) %>%
          .[, !!dot := .SD[, !!dot][na_index], by = !!by] %>%
          .[, na_index := NULL] %>%
          .[]
      ))
    }
  }
  .data
}

fillup <- function(.data, ..., by = NULL) {
  if (!is.data.frame(.data)) stop(".data must be a data.frame or data.table")
  if (!is.data.table(.data)) .data <- as.data.table(.data)

  dots <- enexprs(...)
  by <- enexpr(by)

  for (dot in dots) {
    dot_type <- .data %>% dt_pull(!!dot) %>% class()

    if (dot_type %in% c("integer", "double", "numeric")) {
      .data %>%
        dt_mutate(!!dot := nafill(!!dot, type = "nocb"), by = !!by)
    } else if (dot_type %in% c("character", "logical", "factor")) {
      eval_tidy(expr(
        .data[, ':='(na_index = 1:.N), by = !!by] %>%
          dt_mutate(na_index = fifelse(is.na(!!dot), NA_integer_, na_index)) %>%
          dt_mutate(na_index = nafill(na_index, type = "nocb"), by = !!by) %>%
          .[, !!dot := .SD[, !!dot][na_index], by = !!by] %>%
          .[, na_index := NULL] %>%
          .[]
      ))
    }
  }
  .data
}