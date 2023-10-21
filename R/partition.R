
globalVariables(c('area', 'area_alt', 'aspect', 'xmin', 'xmax', 'ymin', 'ymax',
                  'target', 'val'))


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Create a data.frame of rectangular areas of the target value in the matrix
#' 
#' @inheritParams max_rect_under_histogram
#' @param mat matrix
#' @param target target value
#'
#' @importFrom stats ave
#' @importFrom utils head
#'
#' @return data.frame
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
partition_matrix_single <- function(mat, target, ar_penalty = 0) {
  
  max_areas <- list()
  
  while (TRUE) {
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # 0/1 matrix indicating where the target value is.
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    s   <- mat
    s[] <- as.integer(s == target)
    mode(s) <- 'integer'
    
    if (all(as.vector(s) == 0)) {
      # print("No target values left")
      break
    }
    
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Cumulative counts of the target value vertically.
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    s <- apply(s, 2, \(x) ave(x, cumsum(x == 0), FUN = cumsum))
    
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Find largest rectangle by
    #   * find the 'max area under histogram' for each row
    #   * select the row with the largest 'max area under histogram'
    #   * if max area is tied, prefer areas with aspect ratio closest to 1
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    areas <- lapply(
      seq(nrow(s)), 
      function(i) {
        # print(i)
        res <- max_rect_under_histogram(s[i,], ar_penalty = ar_penalty)
        res$ymin <- i - res$h + 1
        res$ymax <- i
        if (res$area < 0) {
          NULL
        } else {
          as.data.frame(res)
        }
      })
    
    
    area_df <- do.call(rbind, areas)
    
    
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Sort the area by some criteria and then pick the top one
    #    * pick largest area (greedy!)
    #    * if multiple areas of the same maximum size
    #         * choose area with aspect ratio closest to 1
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    area_df <- subset(area_df, area > 0)
    area_df <- area_df[with(area_df, order(-area_alt, ar_alt)),]
    
    if (nrow(area_df) == 0) {
      # zero areas can happen if all row is "-Inf"
      # print("No non-zero area")
      break;
    }
    
    # Note: If all areas == 1, then can probably add them in one go
    # rather than 1-at-a-time

    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Best area is at the top
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    max_area <- area_df[1,]
    
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Add the max_area from this iteration to the list of all max areas
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    max_areas <- c(max_areas, list(max_area))
    
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Change the values of current max area in the orignal matrix to -Inf 
    # This will mark it as "taken" so that the next iteration will ignore them
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    mat[(max_area$ymin):(max_area$ymax), (max_area$xmin):(max_area$xmax)] <- -Inf
    
  }
  
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # All areas for this target
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  max_areas <- do.call(rbind, max_areas)
  max_areas$target <- target
  
  max_areas
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Determine all rectangular regions of the same value in the matrix
#' 
#' @inheritParams max_rect_under_histogram
#' @param mat matrix
#' 
#' @return data.frame
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
partition_matrix <- function(mat, ar_penalty = 0) {
  
  rects <- lapply(
    unique(as.vector(mat)), 
    \(target) partition_matrix_single(mat, target = target, ar_penalty = ar_penalty)
  )
  
  do.call(rbind, rects)
}



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Plot all rects in a matrix
#'
#' @param rects rects returned by \code{partition_matrix()}
#' @param mat matrix
#'
#' @return ggplot object
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
plot_rects <- function(rects, mat = NULL) {
  
  p <- NULL
  
  if (requireNamespace('ggplot2', quietly = TRUE)) {
    p <- ggplot2::ggplot(rects) +
      ggplot2::geom_rect(
        mapping = ggplot2::aes(
          xmin = xmin - 1, xmax = xmax, ymin = ymin - 1, ymax = ymax,
          fill = as.factor(target)
        ),
        alpha = 0.5,
        colour = 'black'
      ) + 
      ggplot2::scale_y_reverse() +
      ggplot2::coord_equal() +
      ggplot2::theme_void() 
    
    if (!is.null(mat)) {
      text_df <- data.frame(
        x   = rep(seq(ncol(mat)), each = nrow(mat)),
        y   = rep(seq(nrow(mat)), ncol(mat)),
        val = as.character(as.vector(mat))
      )
      
      p <- p + 
        ggplot2::geom_text(
          data = text_df, 
          mapping = ggplot2::aes(x - 0.5, y - 0.5, label = val)
        ) + 
        ggplot2::theme(legend.position = 'none')
    } else {
      p <- p + ggplot2::theme(legend.position = 'bottom')
    }
    
    p
  } else {
    stop("{ggplot2} package needed for plotting")
  }
  
  p
}



if (FALSE) {
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Create a random matrix
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  set.seed(2)
  w <- 15
  h <- 15
  mat <- matrix(sample(c(1, 2), w*h, replace = TRUE, prob = c(4, 1)), h, w)
  
  rects <- partition_matrix(mat, ar_penalty = 1)
  
  plot_rects(rects, mat)
  
}
