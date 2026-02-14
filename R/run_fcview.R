#' @title Launch FCView Shiny Application
#'
#' @description
#'   Launches the FCView interactive Shiny application for exploring and
#'   analyzing flow cytometry data. The app provides tools for visualizing
#'   dimensionality reduction plots, cluster heatmaps, abundance analysis,
#'   statistical modeling, and more.
#'
#' @param launch.browser
#'   Logical; if `TRUE` (default), opens the app in the default web browser.
#'   If `FALSE`, the app runs in the RStudio Viewer pane or R console.
#'
#' @param port
#'   Integer or `NULL`; port number for the Shiny app. If `NULL` (default),
#'   Shiny will automatically select an available port.
#'
#' @param host
#'   Character; the IPv4 or IPv6 address to listen on. Default is `"127.0.0.1"`
#'   (localhost). Use `"0.0.0.0"` to allow remote connections.
#'
#' @param ...
#'   Additional arguments passed to `shiny::runApp()`.
#'
#' @details
#'   The FCView app is designed to work with data objects prepared using the
#'   FCSimple package workflow. Data should be saved as an .RData file containing
#'   an object named `fcs_data` with the following structure:
#'   - `data`: numeric matrix of cells × features
#'   - `source`: character vector of sample identifiers
#'   - `metadata`: data frame with sample-level metadata (must include `patient_ID`)
#'   - `cluster`: list containing cluster assignments, abundance, and counts
#'   - `umap` or `tsne`: list with `coordinates` data frame (optional)
#'   - `cluster_heatmap`: list with heatmap tile data
#'
#'   Use `FCSimple::fcs_prepare_fcview_object()` to prepare your analysis object
#'   for upload to the app.
#'
#' @return
#'   No return value. Launches the Shiny application.
#'
#' @examples
#' \dontrun{
#'   # Launch FCView app in browser
#'   FCView::run_fcview()
#'
#'   # Launch on specific port
#'   FCView::run_fcview(port = 3838)
#'
#'   # Launch and allow remote connections
#'   FCView::run_fcview(host = "0.0.0.0", port = 8080)
#' }
#'
#' @seealso
#'   \code{\link[shiny]{runApp}}
#'
#' @export
run_fcview <- function(launch.browser = TRUE, port = NULL, host = "127.0.0.1", ...) {
  app_dir <- system.file("app", package = "FCView")

  if (app_dir == "") {
    stop("Could not find FCView app directory. Please reinstall the package.")
  }

  shiny::runApp(
    appDir = app_dir,
    launch.browser = launch.browser,
    port = port,
    host = host,
    ...
  )
}
