library(mlLang)
context("Parser")

library(gbm)
library(mlbench)
library(mice)

test_that("parser is working with iris data", {
  data(iris)
  data(Sonar)
  # Test simple iris classification

  set.seed(0)

  task <- parseMlTask(system.file("inst", "XML", "iris_classification.xml", package = "mlLang"))
  expect_is(task, "ParsedMlTask")

  model <- executeMlTask(task, iris)
  expect_is(model, "train")
  expect_equal(model$method, "gbm")
  expect_equal(model$modelType, "Classification")
  expect_equal(model$metric, "Accuracy")

  expect_equal(model$finalModel$xNames, c("Sepal.Length", "Sepal.Width", "Petal.Length", "Petal.Width"))

  expect_equal(model$preProcess$method$center, c("Sepal.Length", "Sepal.Width", "Petal.Length", "Petal.Width"))
  expect_equal(model$preProcess$method$scale, c("Sepal.Length", "Sepal.Width", "Petal.Length", "Petal.Width"))

  expect_equal(model$bestTune$n.trees, 3)
  expect_equal(model$bestTune$interaction.depth, 20)
  expect_equal(model$bestTune$shrinkage, 0.2)
  expect_equal(model$bestTune$n.minobsinnode, 10)

  expect_equal(mean(model$results$Accuracy), 0.9414815, tolerance = 0.1)

  # Test simple iris classification with bootstrap

  set.seed(0)

  task <- parseMlTask(system.file("inst", "XML", "iris_classification_bootstrap.xml", package = "mlLang"))
  model <- executeMlTask(task, iris)

  expect_equal(nrow(model$resample), 5)

  expect_equal(model$bestTune$n.trees, 1)
  expect_equal(model$bestTune$interaction.depth, 20)
  expect_equal(model$bestTune$shrinkage, 0.2)
  expect_equal(model$bestTune$n.minobsinnode, 10)

  expect_equal(mean(model$results$Accuracy), 0.8887583, tolerance = 0.01)

  # Test simple iris regression

  set.seed(0)

  task <- parseMlTask(system.file("inst", "XML", "iris_regression.xml", package = "mlLang"))
  model <- executeMlTask(task, iris)

  expect_is(model, "train")
  expect_equal(model$method, "gbm")
  expect_equal(model$modelType, "Regression")
  expect_equal(model$metric, "RMSE")

  expect_equal(model$bestTune$n.trees, 4)
  expect_equal(model$bestTune$interaction.depth, 20)
  expect_equal(model$bestTune$shrinkage, 0.2)
  expect_equal(model$bestTune$n.minobsinnode, 10)

  expect_equal(mean(model$results$RMSE), 0.5493137)


  #Test advanced features
  set.seed(0)
  Sonar_copy = Sonar
  Sonar_copy [4:10,3] <- rep(NA,7)
  Sonar_copy [1:5,4] <- NA

  task <- parseMlTask(system.file("inst", "XML", "sonar_classification_roc_plot_missing_values.xml", package = "mlLang"))
  model <- executeMlTask(task, Sonar_copy)

  expect_equal(model$method, "svmLinear")
  expect_equal(model$modelType, "Classification")
  expect_equal(model$metric, "ROC")

  expect_equal(model$bestTune$C, 1)
  expect_equal(mean(model$results$ROC), 0.8138384,tolerance = 0.01)

  plotFilename = task$mlTask$Plotting$Plot$filename
  plotFilename <- paste(plotFilename, ".png", sep="")

  expect_that(file.exists(plotFilename),is_true())
  unlink(plotFilename)

  # Test wrong xml-file

  expect_warning({ task_error <- parseMlTask(system.file("inst", "XML", "iris_error.xml", package = "mlLang")) })
  expect_warning({ model_error <- executeMlTask(task_error, iris) })
  expect_false(model_error)
})
