test_that("PKNCAdose", {
  tmp.conc <- generate.conc(nsub=5, ntreat=2, time.points=0:24)
  tmp.conc.analyte <- generate.conc(nsub=5, ntreat=2, time.points=0:24,
                                    nanalytes=2)
  tmp.conc.study <- generate.conc(nsub=5, ntreat=2, time.points=0:24,
                                  nstudies=2)
  tmp.conc.analyte.study <- generate.conc(nsub=5, ntreat=2, time.points=0:24,
                                          nanalytes=2, nstudies=2)
  tmp.dose <- generate.dose(tmp.conc)
  rownames(tmp.dose) <- NULL
  tmp.dose.analyte <- generate.dose(tmp.conc.analyte)
  tmp.dose.study <- generate.dose(tmp.conc.study)
  tmp.dose.analyte.study <- generate.dose(tmp.conc.analyte.study)

  # Data exists
  expect_error(PKNCAdose(data.frame()),
               regexp="data must have at least one row.",
               info="PKNCAconc requires data")

  # Variables present
  expect_error(PKNCAdose(tmp.dose, formula=dosea~time|treatment+ID),
               regexp="The left side formula must be a variable in the data, empty, or '.'.",
               info="All formula parameters must be in the data (LHS)")
  expect_error(PKNCAdose(tmp.dose, formula=dose~timea|treatment+ID),
               regexp="The right side formula must be a variable in the data or '.'.",
               info="All formula parameters must be in the data (RHS)")
  expect_error(PKNCAdose(tmp.dose, formula=dose~time|treatmenta+ID),
               regexp="All of the variables in the groups must be in the data",
               info="All formula parameters must be in the data (groups)")
  expect_error(PKNCAdose(tmp.dose, formula=dosea~time|treatment/ID),
               regexp="formula for PKNCAdose may not include a slash",
               info="The formula string must not contain any slashes")

  # Number of variables
  expect_error(PKNCAdose(tmp.dose, formula=dose+ID~time|treatment+ID),
               regexp="The left side of the formula must have zero or one variable",
               info="The right number of parameters in the formula (LHS)")
  expect_error(PKNCAdose(tmp.dose, formula=dose~time+ID|treatment+ID),
               regexp="The right side of the formula \\(excluding groups\\) must have exactly one variable",
               info="The right number of parameters in the formula (RHS)")
  expect_error(PKNCAdose(tmp.dose, formula=~time+ID|treatment+ID),
               regexp="The right side of the formula \\(excluding groups\\) must have exactly one variable",
               info="The right number of parameters in the formula (RHS)")

  # Accept "." on either side of the ~
  expect_equal(
    PKNCAdose(tmp.dose, formula=.~time|treatment+ID),
    structure(
      list(
        data =
          cbind(
            tmp.dose,
            data.frame(
              exclude = NA_character_,
              route = "extravascular",
              duration = 0,
              stringsAsFactors = FALSE
            )
          ),
        formula = . ~ time | treatment + ID,
        columns =
          list(
            dose = character(),
            time = "time",
            groups =
              list(
                group_vars = c("treatment", "ID"),
                group_analyte = character()
              ),
            exclude = "exclude",
            route = "route",
            duration = "duration"
          ),
        units = list()
      ),
      class = c("PKNCAdose", "list")
    ),
    info="PKNCAdose accepts . on the left side of the formula"
  )
  expect_equal(
    PKNCAdose(tmp.dose, formula = dose~.|treatment+ID),
    structure(
      list(
        data =
          cbind(
            tmp.dose,
            data.frame(
              exclude = NA_character_,
              route = "extravascular",
              duration = 0,
              stringsAsFactors = FALSE
            )
          ),
        formula = dose ~ . | treatment + ID,
        columns =
          list(
            dose = "dose",
            time = character(),
            groups =
              list(
                group_vars = c("treatment", "ID"),
                group_analyte = character()
              ),
            exclude = "exclude",
            route = "route",
            duration = "duration"
          ),
        units = list()
      ),
      class = c("PKNCAdose", "list")
    ),
    info = "PKNCAdose accepts . on the right side of the formula"
  )

  tmp.dose.na <- tmp.dose
  tmp.dose.na$time[1] <- NA
  expect_error(PKNCAdose(tmp.dose.na, formula=dose~time|treatment+ID),
               regexp="Some but not all values are missing for the independent variable",
               info="Dose time must either all or none be NA.")
  # Keys must be unique
  bad.dose.analyte <- unique(tmp.conc.analyte[,c("treatment", "ID", "analyte")])
  bad.dose.analyte$dose <- 1
  bad.dose.analyte$time <- 0
  expect_error(
    PKNCAdose(bad.dose.analyte, formula=dose~time|treatment+ID),
    regexp="Rows that are not unique per group and time"
  )

  expect_equal(
    PKNCAdose(
      tmp.dose,
      formula=dose~time|treatment+ID
    ),
    PKNCAdose(
      dplyr::as_tibble(tmp.dose),
      formula=dose~time|treatment+ID
    ),
    info="tibble and data.frame classes both work and create identical objects"
  )
})

test_that("PKNCAdose without a data.frame as input", {
  tmp <- structure(list(), class="foo")
  captured_message <- tryCatch(as.data.frame(tmp), error=function(e) e$message)
  expect_error(PKNCAdose(tmp, formula=.~time|treatment+ID),
               regexp=captured_message,
               fixed=TRUE,
               info="PKNCAdose tries to make arbitrary data into a data.frame")
})

test_that("PKNCAdose model.frame", {
  tmp.conc <- generate.conc(nsub=5, ntreat=2, time.points=0:24)
  tmp_conc_single <- generate.conc(nsub=1, ntreat=1, time.points=0:24)
  tmp.conc.analyte <- generate.conc(nsub=5, ntreat=2, time.points=0:24,
                                    nanalytes=2)
  tmp.conc.study <- generate.conc(nsub=5, ntreat=2, time.points=0:24,
                                  nstudies=2)
  tmp.conc.analyte.study <- generate.conc(nsub=5, ntreat=2, time.points=0:24,
                                          nanalytes=2, nstudies=2)
  tmp.dose <- generate.dose(tmp.conc)
  tmp_dose_single <- generate.dose(tmp_conc_single)

  mydose1 <- PKNCAdose(formula=dose~time|treatment+ID, data=tmp.dose)
  expect_equal(getDepVar.PKNCAdose(mydose1),
               rep(1:2, each=5),
               info="getDepVar.PKNCAdose works with two-sided formula")
  expect_equal(getIndepVar.PKNCAdose(mydose1),
               rep(0, 10),
               info="getIndepVar.PKNCAdose works with two-sided formula")
  expect_equal(model.frame.PKNCAdose(mydose1),
               data.frame("getDepVar.PKNCAdose(formula)"=rep(1:2, each=5),
                          "getIndepVar.PKNCAdose(formula)"=0,
                          treatment=rep(c("Trt 1", "Trt 2"), each=5),
                          ID=rep(1:5, 2),
                          stringsAsFactors=FALSE),
               ignore_attr=TRUE,
               info="model.frame.PKNCAdose works with two-sided formula")

  mydose2 <- PKNCAdose(formula=~time|treatment+ID, data=tmp.dose)
  expect_equal(getDepVar.PKNCAdose(mydose2),
               rep(NA_integer_, 10),
               info="getDepVar.PKNCAdose works with one-sided formula")
  expect_equal(getIndepVar.PKNCAdose(mydose2),
               rep(0, 10),
               info="getIndepVar.PKNCAdose works with one-sided formula")
  expect_equal(model.frame.PKNCAdose(mydose2),
               data.frame("getDepVar.PKNCAdose(formula)"=NA_integer_,
                          "getIndepVar.PKNCAdose(formula)"=0,
                          treatment=rep(c("Trt 1", "Trt 2"), each=5),
                          ID=rep(1:5, 2),
                          stringsAsFactors=FALSE),
               ignore_attr=TRUE,
               info="model.frame.PKNCAdose works with one-sided formula")

  mydose3 <- PKNCAdose(formula=.~time|treatment+ID, data=tmp.dose)
  expect_equal(getDepVar.PKNCAdose(mydose3),
               rep(NA_integer_, 10),
               info="getDepVar.PKNCAdose works with one-sided formula ('.' on LHS)")
  expect_equal(getIndepVar.PKNCAdose(mydose3),
               rep(0, 10),
               info="getIndepVar.PKNCAdose works with one-sided formula ('.' on LHS)")
  expect_equal(model.frame.PKNCAdose(mydose3),
               data.frame("getDepVar.PKNCAdose(formula)"=NA_integer_,
                          "getIndepVar.PKNCAdose(formula)"=0,
                          treatment=rep(c("Trt 1", "Trt 2"), each=5),
                          ID=rep(1:5, 2),
                          stringsAsFactors=FALSE),
               ignore_attr=TRUE,
               info="model.frame.PKNCAdose works with one-sided formula ('.' on LHS)")

  mydose4 <- PKNCAdose(formula=dose~.|treatment+ID, data=tmp.dose)
  expect_equal(getDepVar.PKNCAdose(mydose4),
               rep(1:2, each=5),
               info="getDepVar.PKNCAdose works with one-sided formula ('.' on RHS)")
  expect_equal(getIndepVar.PKNCAdose(mydose4),
               rep(NA_integer_, 10),
               info="getIndepVar.PKNCAdose works with one-sided formula ('.' on RHS)")
  expect_equal(model.frame.PKNCAdose(mydose4),
               data.frame("getDepVar.PKNCAdose(formula)"=rep(1:2, each=5),
                          "getIndepVar.PKNCAdose(formula)"=NA_integer_,
                          treatment=rep(c("Trt 1", "Trt 2"), each=5),
                          ID=rep(1:5, 2),
                          stringsAsFactors=FALSE),
               ignore_attr=TRUE,
               info="model.frame.PKNCAdose works with one-sided formula ('.' on RHS)")

  # You can't give multiple rows per group if you don't give time.
  expect_error(PKNCAdose(formula=dose~.|treatment+ID, data=rbind(tmp.dose, tmp.dose)),
               regexp="Rows that are not unique per group and time.*found within dosing data",
               info="Dosing must have unique values with time and group")

  expect_equal(
    group_vars.PKNCAdose(PKNCAdose(tmp.dose, formula=dose~time|treatment+ID)),
    c("treatment", "ID")
  )
  expect_equal(
    group_vars.PKNCAdose(PKNCAdose(tmp_dose_single, formula=dose~time)),
    character(0),
    info="Ungrouped data works with group_vars"
  )
})

test_that("print.PKNCAdose", {
  tmp.conc <- generate.conc(nsub=5, ntreat=2, time.points=0:24)
  tmp.dose <- generate.dose(tmp.conc)
  mydose <- PKNCAdose(tmp.dose, formula=dose~time|treatment+ID)
  tmp.conc.nogroup <- generate.conc(nsub=1, ntreat=1, time.points=0:24)
  tmp.dose.nogroup <- generate.dose(tmp.conc.nogroup)
  mydose.nogroup <- PKNCAdose(tmp.dose.nogroup, formula=dose~time)

  expect_output(print(mydose),
                regexp="Formula for dosing:
 dose ~ time | treatment + ID
Nominal time column is not specified.

First 6 rows of dosing data:
 treatment ID dose time exclude         route duration
     Trt 1  1    1    0    <NA> extravascular        0
     Trt 1  2    1    0    <NA> extravascular        0
     Trt 1  3    1    0    <NA> extravascular        0
     Trt 1  4    1    0    <NA> extravascular        0
     Trt 1  5    1    0    <NA> extravascular        0
     Trt 2  1    2    0    <NA> extravascular        0",
                fixed=TRUE,
                info="Generic print.PKNCAdose works")
  expect_output(print(mydose.nogroup),
                regexp="Formula for dosing:
 dose ~ time
Nominal time column is not specified.

Data for dosing:
 treatment ID dose time exclude         route duration
     Trt 1  1    1    0    <NA> extravascular        0",
                fixed=TRUE,
                info="Generic print.PKNCAdose works with no groups")

  expect_output(print(mydose, n=-5),
                regexp="Formula for dosing:
 dose ~ time | treatment + ID
Nominal time column is not specified.

First 5 rows of dosing data:
 treatment ID dose time exclude         route duration
     Trt 1  1    1    0    <NA> extravascular        0
     Trt 1  2    1    0    <NA> extravascular        0
     Trt 1  3    1    0    <NA> extravascular        0
     Trt 1  4    1    0    <NA> extravascular        0
     Trt 1  5    1    0    <NA> extravascular        0",
                fixed=TRUE,
                info="Generic print.PKNCAdose works")

  expect_output(print(mydose, summarize=TRUE),
                regexp="Formula for dosing:
 dose ~ time | treatment + ID
Nominal time column is not specified.

Number unique entries in each group:
 treatment ID
         2  5",
                fixed=TRUE,
                info="Summary print.PKNCAdose works")

  expect_output(
    print(mydose.nogroup, summarize=TRUE),
    regexp="No groups"
  )
})

test_that("PKNCAdose with exclusions", {
  tmp.conc <- generate.conc(nsub=2, ntreat=2, time.points=0:24)
  tmp.dose <- generate.dose(tmp.conc)
  tmp.dose$excl <- NA_character_
  mydose <- PKNCAdose(tmp.dose, formula=dose~time|treatment+ID, exclude="excl")
  expect_equal(
    mydose,
    structure(
      list(
        data =
          cbind(
            tmp.dose,
            data.frame(
              route = "extravascular",
              duration = 0,
              stringsAsFactors = FALSE
            )
          ),
        formula = dose~time|treatment+ID,
        columns =
          list(
            dose = "dose",
            time = "time",
            groups =
              list(
                group_vars = c("treatment", "ID"),
                group_analyte = character()
              ),
            exclude = "excl",
            route = "route",
            duration = "duration"
          ),
        units = list()
      ),
      class=c("PKNCAdose", "list")
    )
  )
})

test_that("PKNCAdose route and duration", {
  tmp.conc <- generate.conc(nsub=2, ntreat=2, time.points=0:24)
  tmp.dose <- generate.dose(tmp.conc)
  expect_equal(PKNCAdose(tmp.dose, formula=dose~time|treatment+ID),
               PKNCAdose(tmp.dose, formula=dose~time|treatment+ID, route="extravascular"),
               info="route is assumed as extravascular")
  expect_equal(PKNCAdose(tmp.dose, formula=dose~time|treatment+ID),
               PKNCAdose(tmp.dose, formula=dose~time|treatment+ID, duration=0),
               info="duration is assumed as 0")
  expect_equal(PKNCAdose(tmp.dose, formula=dose~time|treatment+ID),
               PKNCAdose(tmp.dose, formula=dose~time|treatment+ID, duration=0, route="extravascular"),
               info="route and duration are correctly assumed")
  dose.iv <- PKNCAdose(tmp.dose, formula=dose~time|treatment+ID, duration=0, route="intravascular")
  dose.ev <- PKNCAdose(tmp.dose, formula=dose~time|treatment+ID, duration=0, route="extravascular")
  expect_equal(dose.iv,
               {
                 tmp <- dose.ev
                 tmp$data$route <- "intravascular"
                 tmp
               },
               info="Intravascular route works")
  expect_error(PKNCAdose(tmp.dose, formula=dose~time|treatment+ID, duration=0, route="foo"),
               regexp="route must have values of either 'extravascular' or 'intravascular'.  Please set to one of those values and retry.",
               info="route must be an accepted value")
  tmp.dose.iv <- tmp.dose
  tmp.dose.iv$route <- "intravascular"
  # Note that the column names are in a different order when specified
  # in the input data.frame or not.
  expect_equal(
    {
      tmp <- PKNCAdose(tmp.dose, formula=dose~time|treatment+ID, duration=0, route="intravascular")
      tmp$data <- tmp$data[,sort(names(tmp$data))]
      tmp
    },
    {
      tmp <- PKNCAdose(tmp.dose.iv, formula=dose~time|treatment+ID, duration=0, route="route")
      tmp$data <- tmp$data[,sort(names(tmp$data))]
      tmp
    },
    ignore_attr=TRUE
  )

})

test_that("time.nominal within PKNCAdose", {
  tmp.conc <- generate.conc(nsub=5, ntreat=2, time.points=0:24)
  tmp.dose <- generate.dose(tmp.conc)
  tmp.dose$nom_time <- tmp.dose$time
  rownames(tmp.dose) <- NULL
  expect_equal(
    PKNCAdose(tmp.dose, formula=dose~time|treatment+ID,
              time.nominal="nom_time"),
    structure(list(
      data=
        cbind(
          tmp.dose,
          data.frame(
            exclude=NA_character_,
            route="extravascular",
            duration=0,
            stringsAsFactors=FALSE
          )
        ),
      formula = dose ~ time | treatment + ID,
      columns =
        list(
          dose = "dose",
          time = "time",
          groups = list(group_vars = c("treatment", "ID"), group_analyte = character()),
          exclude = "exclude",
          route = "route",
          duration = "duration",
          time.nominal = "nom_time"
        ),
      units = list()
    ),
    class = c("PKNCAdose", "list")),
    info="PKNCAdose accepts time.nominal"
  )
  expect_error(PKNCAdose(tmp.dose, formula=dose~time|treatment+ID,
                         time.nominal="foo"),
               regexp="time.nominal, if given, must be a column name in the input data",
               info="PKNCAdose time.nominal must be a column in the data")
  # Test printing
  dose_with_nom_time <- PKNCAdose(tmp.dose, formula=dose~time|treatment+ID,
                                  time.nominal="nom_time")
  expect_output(print(dose_with_nom_time),
                regexp="Formula for dosing:
 dose ~ time | treatment + ID
Nominal time column is: nom_time

First 6 rows of dosing data:
 treatment ID dose time nom_time exclude         route duration
     Trt 1  1    1    0        0    <NA> extravascular        0
     Trt 1  2    1    0        0    <NA> extravascular        0
     Trt 1  3    1    0        0    <NA> extravascular        0
     Trt 1  4    1    0        0    <NA> extravascular        0
     Trt 1  5    1    0        0    <NA> extravascular        0
     Trt 2  1    2    0        0    <NA> extravascular        0",
                fixed=TRUE,
                info="Generic print.PKNCAdose works")
})

test_that("setDuration", {
  tmp.conc <- generate.conc(nsub=5, ntreat=2, time.points=0:24)
  tmp.dose <- generate.dose(tmp.conc)
  tmp.dose$nom_time <- tmp.dose$time
  rownames(tmp.dose) <- NULL
  mydose <- PKNCAdose(tmp.dose, formula=dose~time|treatment+ID)
  expect_message(
    expect_equal(
      setDuration(mydose),
      mydose,
      info="No changes with no arguments"
    ),
    class = "pknca_foundcolumn_duration"
  )
  expect_error(setDuration(mydose, duration="foo", rate="bar"),
               regexp="Both duration and rate cannot be given at the same time",
               fixed=TRUE,
               info="Cannot give both duration and rate")
  expect_message(expect_error(
    setDuration(mydose, duration="foobar"),
    regexp="duration must be numeric without missing (NA) or infinite values, and all values must be >= 0",
    fixed=TRUE,
    info="Cannot give both duration as non-numeric"),
    class = "pknca_foundcolumn_duration"
  )

  duration_example <- suppressMessages(setDuration(mydose, rate=2))
  expect_true(all(mydose$data$duration == 0))
  expect_equal(
    duration_example$data$duration,
    duration_example$data$dose/2
  )
  expect_equal(duration_example$columns$duration, "duration")
})

test_that("Test uniqueness after excluding rows (#298)", {
  repeated_with_exclusion <-
    data.frame(
      dose = 1,
      time = c(0, 0),
      id = 1,
      exclude = c(NA, "duplicate")
    )
  expect_error(
    PKNCAdose(repeated_with_exclusion, formula=dose~time|id),
    regexp="Rows that are not unique per group and time.*dosing"
  )
  expect_s3_class(
    PKNCAdose(repeated_with_exclusion, formula=dose~time|id, exclude = "exclude"),
    class = "PKNCAdose"
  )
  repeated_with_exclusion_firstrow <-
    data.frame(
      dose = 1,
      time = c(0, 0),
      id = 1,
      exclude = c("duplicate", NA)
    )
  expect_s3_class(
    PKNCAdose(repeated_with_exclusion_firstrow, formula=dose~time|id, exclude = "exclude"),
    class = "PKNCAdose"
  )

  repeated_with_exclusion_nogroup <-
    data.frame(
      dose = 1,
      time = c(0, 0),
      id = 1,
      exclude = c("duplicate", NA)
    )
  expect_s3_class(
    PKNCAdose(repeated_with_exclusion_firstrow, formula=dose~., exclude = "exclude"),
    class = "PKNCAdose"
  )
  expect_s3_class(
    PKNCAdose(repeated_with_exclusion_firstrow, formula=dose~.|id, exclude = "exclude"),
    class = "PKNCAdose"
  )
  repeated_with_exclusion_row2 <-
    data.frame(
      dose = 1,
      time = c(0, 0),
      id = 1,
      exclude = c(NA, "duplicate")
    )
  expect_s3_class(
    PKNCAdose(repeated_with_exclusion_row2, formula=dose~.|id, exclude = "exclude"),
    class = "PKNCAdose"
  )
})

test_that("PKNCAdose units (#336)", {
  d <- data.frame(dose = 1, time = 0, doseu_x = "A")

  # No units
  o_dose <- PKNCAdose(data = d, dose~time)
  expect_equal(o_dose$units, list())
  expect_null(o_dose$columns$doseu)

  # Each unit column individually
  o_dose <- PKNCAdose(data = d, dose~time, doseu = "doseu_x")
  expect_equal(o_dose$units, list())
  expect_equal(o_dose$columns$doseu, structure("doseu_x", unit_type = "column"))

  # Each unit as a value, not a column
  o_dose <- PKNCAdose(data = d, dose~time, doseu = "doseu_y")
  expect_equal(o_dose$units, list(doseu = structure("doseu_y", unit_type = "value")))
  expect_null(o_dose$columns$doseu)

  # Preferred units
  expect_error(
    PKNCAdose(data = d, dose~time, doseu_pref = "doseu_z"),
    regexp = "Preferred units may not be set unless original units are set: doseu_pref"
  )
  o_dose <- PKNCAdose(data = d, dose~time, doseu = "doseu_y", doseu_pref = "doseu_z")
  expect_equal(
    o_dose$units,
    list(
      doseu = structure("doseu_y", unit_type = "value"),
      doseu_pref = structure("doseu_z", unit_type = "value")
    )
  )
  expect_null(o_dose$columns$doseu)

  o_dose <- PKNCAdose(data = d, dose~time, doseu = "doseu_x", doseu_pref = "doseu_z")
  expect_equal(o_dose$units, list(doseu_pref = structure("doseu_z", unit_type = "value")))
  expect_equal(
    o_dose$columns$doseu,
    structure("doseu_x", unit_type = "column")
  )
})
