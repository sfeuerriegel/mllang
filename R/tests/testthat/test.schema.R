library(mlLang)
context("Schema")

test_that("schema is checked correctly with iris data", {
  expect_true(checkSchema(system.file("inst", "XML", "iris_classification.xml", package = "mlLang")))
  expect_true(checkSchema(system.file("inst", "XML", "iris_classification_bootstrap.xml", package = "mlLang")))
  expect_true(checkSchema(system.file("inst", "XML", "iris_regression.xml", package = "mlLang")))

  expect_false(checkSchema(system.file("inst", "XML", "iris_error.xml", package = "mlLang")))
})
