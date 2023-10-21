
globalVariables(c('x', 'y'))

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Find the area of the maximum rectangle under the given histogram
#'
# This implementation is pretty brute force, but makes use of rle() to 
# find matching bars for the current bar, so it was easy to write at least :)
#'
#' Having the guts exposed in this function also help in manually tweaking the 
#' accepted "maximum area rectangle" by penalising areas we don't want.
#' Currently high-aspect-ratio areas are penalised so that areas which 
#' are more square might be chosen (even if actual total area is less)
#' 
#' @param hts histogram bar heights e.g. \code{c(2, 2, 1, 2, 2)}
#' @param ar_penalty Aspect ratio penalty (multiplication factor). Default value
#'        of \code{0} means to return the largest area regardless of aspect ratio.   
#'        Values above 0 are used to reduce the area by this factor multiplied
#'        by the aspect ratio of the rectangle.
#'        Value can be any 
#'        positive floating point number. Useful range: 0-20
#'
#' @export
#' 
#' @examples
#' \dontrun{
#' hts <- c(2, 2, 1, 2, 2)
#' plot_hist_max_rect(hts, rect = NULL)
#' rect <- max_rect_under_histogram(hts)
#' plot_hist_max_rect(hts, rect = rect)
#' 
#' rect <- max_rect_under_histogram(hts, ar_penalty = 1)
#' plot_hist_max_rect(hts, rect = rect)
#' }
#' 
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
max_rect_under_histogram <- function(hts, ar_penalty = 0) {
  
  res <- list(
    area = -Inf
  )
  
  # Short circuit if nothing to do
  if (all(hts <= 0)) {
    return(list(
      area     = 0,
      area_alt = 0, #area_alt,
      ar       = 9, #ar,
      ar_alt   = 9, #ar_alt,
      xmin     = 1, #x_range[1],
      xmax     = 1, #x_range[2],
      h        = 0, #hts[idx],
      w        = 0  #width,
    ))
  }
  
  # for each bar in the histogram
  #   - find matching bars which as this bar height or above
  #   - keep only the bars of matching height which are 
  #     part of a run of bars which include the current bar
  #   - area = height of bar * length of run of matching bars
  for (idx in seq_along(hts)) {
    
    # SOA = Same height Or Above (compared to bar hts[idx])
    ht  <- hts[idx]
    if (ht == 0) next
    soa <- hts >= ht
    
    # Run-length encode the matching bars
    rl <- unclass(rle(soa))
    
    # where to these 'runs' start
    starts <- c(1, head(1 + cumsum(rl$lengths), -1))
    
    # find the 'run' which includes the current bar
    rl_idx <- max(which(idx >= starts))
    
    # how many peers are in this same 'run'?
    # i.e. bars which are same height or above.
    npeers <- rl$lengths[[rl_idx]]
    
    # what are the actual indices of these peers?
    peer_idxs <- starts[rl_idx] + seq_len(npeers) - 1
    x_range   <- range(peer_idxs)
    
    # Total area of this rectangle
    #     = width  * height
    area <- npeers * ht
    
    # Aspect ratio
    width <- diff(x_range) + 1
    ar_alt <- ar <- width/ht
    if (ar_alt < 1) {
      ar_alt <- 1/ar_alt
    }
    
    # Penalise the area by a multiple of its aspect ratio.
    # i.e. Prefer "squarer" areas by artificially reducing
    # the calcualted area (area_alt) by a multiple of the
    # aspect ratio.  
    # Ingore aspect ratio for area = 1 or 2.
    if (area < 3) {
      area_alt <- area
    } else {
      area_alt <- area - ar_penalty * ar_alt
    }
    
    
    if (area_alt > res$area) {
      res$area     <- area
      res$area_alt <- area_alt
      res$ar       <- ar
      res$ar_alt   <- ar_alt
      res$xmin     <- x_range[1]
      res$xmax     <- x_range[2]
      res$h        <- hts[idx]
      res$w        <- width
    }
    
  }
  res
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Plot a histogram and its max rectangle
#' 
#' @param hts bar heights of histogram
#' @param rect output from \code{max_rect_under_histogram()}
#' 
#' @return ggplot object
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
plot_hist_max_rect <- function(hts, rect = NULL) {
  
  p <- NULL
  
  if (requireNamespace('ggplot2', quietly = TRUE)) {
    plot_df <- data.frame(x = seq_along(hts), y = hts)
    
    p <- ggplot2::ggplot(plot_df) + 
      ggplot2::geom_col(ggplot2::aes(x, y), width = 1, fill = 'grey80', colour = 'grey30') + 
      ggplot2::theme_minimal() 
    
    if (!is.null(rect)) {
      p <- p + ggplot2::annotate(
        'rect', 
        xmin     = rect$xmin - 0.5, 
        xmax     = rect$xmax + 0.5,
        ymin     = 0,
        ymax     = rect$h,
        fill     = 'dodgerblue3',
        alpha    = 0.3,
        colour   = 'black', 
        linetype = 2
      )
    }
  } else {
    stop("{ggplot2} package needed for plotting")
  }
  
  p
}



if (FALSE) {
  hts <- c(6, 2, 5, 4, 5, 1, 6) # 12
  max_rect <- max_rect_under_histogram(hts) 
  plot_hist_max_rect(hts, max_rect)
  
  plot_rect(max_rect)
}

