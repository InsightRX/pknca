test_that("check.conversion", {
  good <- LETTERS
  expect_equal(check.conversion(good, as.character), good)
  expect_error(
    expect_warning(
      check.conversion(good, as.numeric)
    ),
    regexp="26 new NA value\\(s\\) created during conversion"
  )
  good <- 1:5
  expect_equal(check.conversion(good, as.character),
               as.character(good))
})

test_that("Rounding", {
  expect_error(roundString(1, c(2, 3)),
               regexp="digits must either be a scalar or the same length as x")
  expect_equal(roundString(11), "11")
  expect_equal(roundString(5), "5")
  expect_equal(roundString(0.05), "0")
  expect_equal(roundString(NA), "NA")
  expect_equal(roundString(NaN), "NaN")
  expect_equal(roundString(Inf), "Inf")
  expect_equal(roundString(-Inf), "-Inf")
  # Respecting the digits
  expect_equal(roundString(0.05, 3), "0.050")
  expect_equal(roundString(123.05, 3), "123.050")
  expect_equal(roundString(c(100, 0.1), 3), c("100.000", "0.100"),
               info="Vectors work with different orders of magnitude work")
  expect_equal(roundString(c(100, 0.1), c(0, 3)), c("100", "0.100"),
               info="Vectors of digits work")
  expect_equal(roundString(c(0.1, NA), digits=3), c("0.100", "NA"),
               info="Mixed inputs (NA, NaN, Inf or numeric), NA")
  expect_equal(roundString(c(0.1, NA, NaN, Inf, -Inf), digits=3),
               c("0.100", "NA", "NaN", "Inf", "-Inf"),
               info="Mixed inputs (NA, NaN, Inf or numeric)")
  # All zeros
  expect_equal(roundString(0, digits=3), "0.000")
  expect_equal(roundString(c(0, NA), digits=3), c("0.000", "NA"))
  # scientific notation
  expect_equal(roundString(1234567, digits=3, sci_range=5), "1.234567000e6",
               info="sci_range works with roundString (even if it looks odd)")
  expect_warning(roundString(1234567, digits=3, si_range=5),
                 regexp="The si_range argument is deprecated, please use sci_range")
  expect_equal(roundString(1234567, digits=3, sci_range=5),
               roundString(1234567, digits=3, sci_range=5),
               info="sci_range works with roundString (even if it looks odd)")
  expect_equal(roundString(1234567, digits=3, sci_range=5, sci_sep="x10^"),
               "1.234567000x10^6",
               info="sci_sep is respected.")
  expect_equal(roundString(c(1e7, 1e10), digits=c(-3, -9), sci_range=5),
               c("1.0000e7", "1.0e10"),
               info="Different numbers of digits for rounding work with roundString")
})

test_that("Significance", {
  expect_equal(signifString(11), "11.0000")
  expect_equal(signifString(5), "5.00000")
  expect_equal(signifString(0.05), "0.0500000")
  expect_equal(signifString(NA), "NA")
  expect_equal(signifString(NaN), "NaN")
  expect_equal(signifString(Inf), "Inf")
  expect_equal(signifString(-Inf), "-Inf")
  # Respecting the digits
  expect_equal(signifString(0.05, 3), "0.0500")
  expect_equal(signifString(123.05, 3), "123")
  expect_equal(signifString(123456.05, 3), "123000")
  expect_warning(signifString(123456.05, 3, si_range=6),
                regexp="The si_range argument is deprecated, please use sci_range")
  expect_warning(
    expect_equal(
      signifString(123456.05, 3, sci_range=6),
      signifString(123456.05, 3, si_range=6),
      info="si_range and sci_range arguments are treated equally."
    )
  )
  expect_equal(signifString(123456.05, 3, sci_range=6), "123000")
  expect_equal(signifString(123456.05, 3, sci_range=5), "1.23e5")
  expect_equal(signifString(-123000.05, 3, sci_range=5), "-1.23e5")
  expect_equal(signifString(999999, 3, sci_range=6), "1.00e6",
               info="Rounding around the edge of the sci_range works correctly (going up)")
  expect_equal(signifString(999999, 7, sci_range=6), "999999.0",
               info="Rounding around the edge of the sci_range works correctly (going staying the same)")
  expect_equal(signifString(-.05, 3), "-0.0500")
  # Exact orders of magnitude work on both sides of 0
  expect_equal(signifString(0.01, 3), "0.0100")
  expect_equal(signifString(1, 3), "1.00")
  expect_equal(signifString(100, 3), "100")
  # Vectors work with different orders of magnitude work
  expect_equal(signifString(c(100, 0.1), 3), c("100", "0.100"))
  # Rounding to a higher number of significant digits works correctly
  expect_equal(signifString(0.9999999, 3), "1.00")
  # Mixed inputs (NA, NaN, Inf or numeric)
  expect_equal(signifString(NA), "NA")
  expect_equal(signifString(c(0.1, NA), digits=3), c("0.100", "NA"))
  expect_equal(signifString(c(0.1, NA, NaN, Inf, -Inf), digits=3),
               c("0.100", "NA", "NaN", "Inf", "-Inf"))
  # All zeros
  expect_equal(signifString(0, digits=3), "0.000")
  expect_equal(signifString(c(0, NA), digits=3), c("0.000", "NA"))

  expect_equal(signifString(1234567, digits=3, sci_range=5, sci_sep="x10^"),
               "1.23x10^6",
               info="sci_sep is respected.")
  expect_equal(signifString(c(1e7, 1e10), digits=3),
               c("1.00e7", "1.00e10"),
               info="Different numbers of digits for rounding work with signifString")

  # Data Frames
  expect_equal(
    signifString(data.frame(A=c(0, 1.111111),
                            B=factor(LETTERS[1:2]),
                            C=LETTERS[1:2],
                            stringsAsFactors=FALSE),
                 digits=3),
    data.frame(A=c("0.000", "1.11"),
               B=factor(LETTERS[1:2]),
               C=LETTERS[1:2],
               stringsAsFactors=FALSE),
    ignore_attr=TRUE,
    info="Data frame significance is calculated correctly"
  )
  expect_equal(
    signifString(data.frame(A=c(0, 1.111111),
                            B=factor(LETTERS[1:2]),
                            C=LETTERS[1:2],
                            stringsAsFactors=FALSE),
                 digits=4),
    data.frame(A=c("0.0000", "1.111"),
               B=factor(LETTERS[1:2]),
               C=LETTERS[1:2],
               stringsAsFactors=FALSE),
    ignore_attr=TRUE,
    info="Data frame digits are respected"
  )
})

test_that("signifString stops when bad arguments are passed", {
  expect_error(
    signifString(1, foo=1),
    regexp="Additional, unsupported arguments were passed",
    fixed=TRUE
  )
})

test_that("max_na and min_na", {
  expect_equal(max_zero_len(1), max(1))
  expect_equal(max_zero_len(c(1, NA)), max(c(1, NA)))
  expect_equal(max_zero_len(1, NA), max(1, NA))
  expect_equal(max_zero_len(1, NA, na.rm=TRUE), max(1, NA, na.rm=TRUE))
  expect_equal(
    max_zero_len(numeric(), na.rm=TRUE),
    NA
  )
  expect_equal(
    max_zero_len(NA_integer_, na.rm=TRUE),
    NA
  )
  expect_equal(
    max_zero_len(NA_integer_, na.rm=TRUE, zero_length=NA_real_),
    NA_real_,
    info="zero_length/na.rm combinations are respected (made zero length)"
  )
  expect_equal(
    max_zero_len(NA_integer_, na.rm=FALSE, zero_length=NA_real_),
    NA_integer_,
    info="zero_length/na.rm combinations are respected (NOT made zero length)"
  )
})

test_that("zero_len_summary", {
  testing_function <- zero_len_summary(mean)
  expect_equal(testing_function(1:5), 3)
  expect_equal(testing_function(1:5, na.rm = TRUE), 3)
  expect_equal(testing_function(), NA)
})
