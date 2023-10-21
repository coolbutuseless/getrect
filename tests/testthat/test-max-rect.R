
test_that("max-rect-under-histogram works", {

  
  hts <- c(6, 2, 5, 4, 5, 1, 6) # 12
  
  expect_equal(
    max_rect_under_histogram(hts)$area,
    12
  )

  hts <- c(4,8,3,1,1,0) # 9
  expect_equal(
    max_rect_under_histogram(hts)$area,
    9
  )
  
  hts <- c(2, 2, 1, 2, 2)
  expect_equal(
    max_rect_under_histogram(hts)$area,
    5
  )
})


test_that("ar_penalty works", {
  hts <- c(2, 2, 1, 2, 2)
  expect_equal(
    max_rect_under_histogram(hts, ar_penalty = 1)$area,
    4
  )
})
