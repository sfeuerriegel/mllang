library(mlLang)
context("Generator")

library(caret)
library(RSNNS)

test_that("generator is working", {
  data(iris)
  predictors <- c("Sepal.Length", "Sepal.Width", "Petal.Length", "Petal.Width")

  output_file <- "output_tests.xml"

  # Test

  set.seed(0)

  task <- newMlTask()

  fitControl <- trainControl(method = "repeatedcv",
                             number = 10,
                             repeats = 3)

  model <- task$train(x = iris[, predictors], y = iris$Species,
                      y_name = "Species",
                      method = "gbm",
                      preProcess = c("center", "scale"),
                      trControl = fitControl,
                      verbose = FALSE)

  expect_equal(model$bestTune$n.trees, 50)
  expect_equal(model$bestTune$interaction.depth, 2)
  expect_equal(model$bestTune$shrinkage, 0.1)
  expect_equal(model$bestTune$n.minobsinnode, 10)

  expect_equal(mean(model$results$Accuracy), 0.9451852)

  write(task, output_file)
  expect_equal(readLines(system.file("inst", "tests", "iris_gbm.xml", package = "mlLang"), warn = FALSE),
               readLines(output_file, warn = FALSE))
  unlink(output_file)

  # Test

  set.seed(0)

  task <- newMlTask()

  fitControl <- trainControl(method = "repeatedcv",
                             number = 10,
                             repeats = 3)


  model <- task$train(x = iris[, predictors], y = iris$Species,
                      y_name = "Species",
                      method = "mlpWeightDecay",
                      preProcess = c("center", "scale"),
                      trControl = fitControl,
                      verbose = FALSE)

  expect_equal(mean(model$results$Accuracy), 0.7424691, tolerance = 0.01)
  write(task, output_file)

  expect_equal(readLines(system.file("inst", "tests", "iris_tuning.xml", package = "mlLang"), warn = FALSE),
               readLines(output_file, warn = FALSE))
  unlink(output_file)

  # Test

  set.seed(0)

  task <- newMlTask()

  partrate <- 0.8

  trainIndex <- task$createDataPartition(iris$Species, p = partrate, list = FALSE)
  irisTrain <- iris[ trainIndex, ]
  irisTest  <- iris[-trainIndex, ]

  gbmGrid <-  expand.grid(n.trees = c(1, 3, 4, 5, 6, 7),
                          shrinkage = c(0.1, 0.2, 0.3),
                          n.minobsinnode = 10,
                          interaction.depth = 10)


  # 10-fold CV and 10 repetitions
  fitControl <- trainControl(method = "boot",
                             number = 10,
                             search = "grid")

  model <- task$train(x = irisTrain[, predictors], y = irisTrain$Species,
                      y_name = "Species",
                      method = "mlpWeightDecay",
                      preProcess = c("center"),
                      trControl = fitControl,
                      verbose = FALSE)

  expect_equal(mean(model$results$Accuracy), 0.724, tolerance = 0.01)

  write(task, output_file)
  expect_equal(readLines(system.file("inst", "tests", "iris_partition.xml", package = "mlLang"), warn = FALSE),
               readLines(output_file, warn = FALSE))
  unlink(output_file)
})
