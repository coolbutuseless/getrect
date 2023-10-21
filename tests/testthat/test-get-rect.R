


test_that("multiplication works", {
  mat <- matrix(
    c(1,1,1,2,3,3,3,
      1,1,2,2,2,3,3,
      1,2,2,2,2,2,3,
      2,2,2,2,2,2,2), 
    nrow = 4, ncol = 7, byrow = TRUE
  )
  
  rects <- partition_matrix(mat, ar_penalty = 0)
  # plot_rects(rects)
  
  expect_equal(
    rects$area, 
    c(4, 1, 1, 10, 3, 1, 1, 1, 4, 1, 1)
  )
  
})
