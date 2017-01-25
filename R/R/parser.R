#' Parsed representation of unified machine learning language
#'
#' R6 class for reading a machine learning task from  an XML file and executing it.
#' @format An \code{\link{R6Class}} generator object
#' @import mice
#' @keywords internal
#' @docType class
#' @export
ParsedMlTask <- R6Class("ParsedMlTask",
  # public attributes and methods
  public = list(

    #attributes
    path_to_xml = NULL,
    mlTask = NULL,

    #constructor
    initialize = function(path_to_xml = NA) {
      self$path_to_xml <- path_to_xml

      # loading xml file
      self$loadXML()

    },


    loadXML = function() {
      if (!checkSchema(self$path_to_xml)) {
        warning("Error in XML file: aborting execution.")
        return(FALSE)
      }

      # loading the XML File to a list
      xmlRawData <- XML::xmlParse(self$path_to_xml)
      self$mlTask <- XML::xmlToList(xmlRawData)
    },

    executeMlTask = function(mlData, logger) {
      if (is.null(self$mlTask)) {
        warning("Not a valid mlTask. Aborting execution..... ")
        return(FALSE)
      }

      # Parse parameter
      logger("Parse XML file")
      dataSplitRate <- private$parseDataSplit()
      preprocessing <- private$parsePreprocessing()
      controlParameter <- private$parseValidationParameter()
      target <- private$parseTarget()
      predictors <- private$parsePredictors()
      algorithm <- private$parseMlAlgorithm()
      metric <- private$parseMetric()
      missingValueHandling <- private$parseMissingValueHandling()
      plotting <- private$parsePlotting()

      loggableControlParameter = controlParameter

      #adding necessary control paramaters to support ROC
      if (metric =="ROC"){
        controlParameter <- c(controlParameter, "classProbs" = TRUE)
        controlParameter <- c(controlParameter, "summaryFunction" = caret::twoClassSummary)

        loggableControlParameter$classProbs <- TRUE
        loggableControlParameter$summaryFunction <- "twoClassSummary"
      }

      # Print parsed parameter
      logger("Data split:")
      logger(dataSplitRate)

      logger("Preprocessings: ")
      logger(preprocessing)

      logger("Validation parameters: ")
      logger(listToString(loggableControlParameter))

      logger("Predictors: ", paste0(unlist(t(predictors)), sep = ";"))

      logger("Target: ", paste0(unlist(t(target)), sep = ";"))

      logger("Metric: ", metric)

      logger("Missing value handling: ", missingValueHandling)

      logger("Plotting: ", listToString(plotting))
      #########
      #Own  preprocessing #######
      ########

      #missing value handling
      if(!is.null(missingValueHandling)){
        logger("Handle missing value")

        if(missingValueHandling == 'removeRows'){
          mlData <- na.omit(mlData)

        }
        else{
          #only apply imputation with mice when there are any missing values
          if (TRUE %in% is.na(mlData)){
            tempData <- mice::mice(mlData, m = 1, method = missingValueHandling)
            mlData <- mice::complete(tempData, 1)
          }
        }
      }

      ##process data types
      variables = rbind(predictors,as.data.frame(target))

      for(i in 1:nrow(variables)) {
        name <- as.character(variables[i,1])
        type <- as.character(variables[i,2])

        if(type == "numeric"){
          mlData[[name]] <- as.numeric(mlData[[name]])
        }

        if(type == "factor"){
          mlData[[name]] <- as.factor(mlData[[name]])
        }
        #we do not need an extra case for automatic, because variables are already set to automatic

      }


      ## Exceuting caret functions

      # Split data
      logger("Splitting data")

      if(!is.null(dataSplitRate)){
        trainIndex <- caret::createDataPartition(mlData[[target$name]], p = dataSplitRate, list = FALSE)
        data_train <- mlData[ trainIndex, ]
        data_test <- mlData[-trainIndex, ]
      } else {
        data_train <- mlData
      }

      # generate grid
      grid <- do.call(expand.grid, algorithm$tuningparameters)

      # validate settings
      fitControl <- do.call(caret::trainControl, controlParameter)

      #training
      logger("Begin training")

      trainparameter <- list()
      trainparameter$x <- data_train[,as.character(predictors$name)]
      trainparameter$y <- data_train[[target$name]]
      trainparameter$preProcess <- preprocessing
      trainparameter$method <- algorithm$method
      trainparameter$trControl <- fitControl
      trainparameter$tuneGrid <- grid

      if (!(algorithm$method %in% c("rpart"))){
        trainparameter$verbose <- FALSE
      }

      if(metric !="automatic"){
        trainparameter$metric <- metric
      }

      fit_model <- do.call(caret::train,trainparameter)

      logger(print.train(fit_model))

      #Testing

      if (!is.null(dataSplitRate)) {
        logger("Predict test data with default caret metric")

        predictedVal <- predict(fit_model, newdata = data_test[,predictors$name])
        modelvalues <- data.frame(obs = data_test[[target$name]], pred=predictedVal)
        fit_model.test_result <- defaultSummary(modelvalues)

        #test_result = confusionMatrix(data = predictedVal, data_test[[target]])
        logger(fit_model.test_result)
      }


      #plotting

      if (!is.null(plotting)) {
        for (i in 1:nrow(plotting)) {
          plotFilename <- as.character(plotting[i, 1])
          plotFilename <- paste(plotFilename, ".png", sep = "")
          type <- as.character(plotting[i,2])

          if (type == "plotValidationResults") {
            p <- ggplot(fit_model)
            ggsave(file = plotFilename)
          }
        }
      }

      return(fit_model)

    } #end execute mltask

    ), # end public functions


  #private attributes and methods
  private = list(

    #ParsingMethods
    parsePreprocessing  = function() {
      if (hasField(self$mlTask, "Preprocessing")) {
        return(unlist(self$mlTask$Preprocessing, use.names = FALSE))
      } else {
        return (NULL)
      }
    },

    parseDataSplit = function() {
      if (hasField(self$mlTask,"Evaluation") && hasField(self$mlTask$Evaluation, "DataSplit")) {
        return(as.numeric(self$mlTask$Evaluation$DataSplit$partitionRate))
      } else {
        return(NULL)
      }

    },

    parseValidationParameter = function() {
      if (hasField(self$mlTask, "Evaluation") && hasField(self$mlTask$Evaluation, "Resampling")) {
        resampling <- self$mlTask$Evaluation$Resampling

        if (hasField(resampling, "CrossValidation")) {
          params <- list("method" = "repeatedcv")
          params <- c(params, "number" = as.numeric(resampling$CrossValidation$numberSubsets))
          params <- c(params, "repeats" = as.numeric(resampling$CrossValidation$repeats))
          return(params)
        }

        if (hasField(resampling, "Bootstrap")){
          params <- list("method" = "boot")
          params <- c(params, "number" = as.numeric(resampling$Bootstrap$number))
          return(params)
        }
      } else {
        return(NULL)
      }

    },

    parseTarget = function() {
      if (hasField(self$mlTask,"DataSpecification") && hasField(self$mlTask$DataSpecification,'predictedVariable')){
        return (self$mlTask$DataSpecification$predictedVariable)
      } else {
        return(NULL)
      }
    },

    parsePredictors = function() {
      if (hasField(self$mlTask,"DataSpecification") && hasField(self$mlTask$DataSpecification,'Predictors')){

        predictors <- list()

        for (variable in self$mlTask$DataSpecification$Predictors){
          predictors$name <- c(predictors$name,variable$name)
          predictors$VariableType <- c(predictors$VariableType,variable$VariableType)
        }

        return (as.data.frame(predictors))

      }else{
        return (NULL)
      }
    },

    parseMlAlgorithm = function() {
      mlAlgorithm <- list()
      tuningparameters <- list()
      method <- ""

      alg <- self$mlTask$Method

      # StochasticGradientBoosting
      if (hasField(alg, "StochasticGradientBoosting")) {
        alg_current <- alg$StochasticGradientBoosting
        method <- "gbm"

        if (hasField(alg_current, "numberTrees")) {
          l <- list("n.trees" = as.numeric(unlist(alg_current$numberTrees, use.names = FALSE)))
          tuningparameters <- c(tuningparameters, l)
        }

        if (hasField(alg_current, "maxTreeDepth")) {
          l <- list("interaction.depth" = as.numeric(unlist(alg_current$maxTreeDepth, use.names = FALSE)))
          tuningparameters <- c(tuningparameters, l)

        }

        if (hasField(alg_current, "shrinkage")) {
          l <- list("shrinkage" = as.numeric(unlist(alg_current$shrinkage, use.names = FALSE)))
          tuningparameters <- c(tuningparameters, l)
        }

        if (hasField(alg_current,'minTerminalNodeSize')){
          l <- list("n.minobsinnode" = as.numeric(unlist(alg_current$minTerminalNodeSize, use.names = FALSE)))
          tuningparameters <- c(tuningparameters, l)
        }
      }

      # linear regression
      if (hasField(alg, "LinearRegression")) {
        alg_current <- alg$LinearRegression
        method <- "lm"

        if (hasField(alg_current, "intercept")) {
          l <- list("intercept" = as.numeric(unlist(alg_current$numberTrees, use.names = FALSE)))
          tuningparameters <- c(tuningparameters, l)
        }
      }

      # neuronal network
      if (hasField(alg, "MultiLayerPerceptron")) {
        alg_current <- alg$MultiLayerPerceptron
        method <- "mlpWeightDecay"

        if (hasField(alg_current, "hiddenUnits")) {
          l <- list("size" = as.numeric(unlist(alg_current$hiddenUnits, use.names = FALSE)))
          tuningparameters <- c(tuningparameters, l)
        }

        if (hasField(alg_current, "weightDecay")) {
          l <- list("decay" = as.numeric(unlist(alg_current$weightDecay, use.names = FALSE)))
          tuningparameters <- c(tuningparameters, l)
        }
      }

      #random forests
      if (hasField(alg,'RandomForest')){
        alg_current <- alg$RandomForest
        method <- 'ranger'

        if(hasField(alg_current,'randomlySelectedPredictors')){
          l <- list('mtry' = as.numeric(unlist(alg_current$randomlySelectedPredictors,use.names=F)))
          tuningparameters <- c(tuningparameters,l)
        }
      }

      #Decision tree with CART
      if (hasField(alg,'CART')){
        alg_current <- alg$CART
        method <- 'rpart'

        if(hasField(alg_current,'complexityParameter')){
          l <- list('cp' = as.numeric(unlist(alg_current$complexityParameter,use.names=F)))
          tuningparameters <- c(tuningparameters,l)
        }
      }

      #linear SVM
      if (hasField(alg,'LinearSVM')){
        alg_current <- alg$LinearSVM
        method <- 'svmLinear'

        if(hasField(alg_current,'cost')){
          l <- list('C' = as.numeric(unlist(alg_current$cost,use.names=F)))
          tuningparameters <- c(tuningparameters,l)
        }
      }

      mlAlgorithm <- c(mlAlgorithm, list("method" = method))

      if (length(tuningparameters) > 0) {
        mlAlgorithm <- c(mlAlgorithm, list("tuningparameters" = tuningparameters))
      }

      return (mlAlgorithm)

    },

    parseMetric = function(){
      if (hasField(self$mlTask,"Evaluation") & hasField(self$mlTask$Evaluation,'Metric')){
        return (self$mlTask$Evaluation$Metric)
      }

      else{
          return (NULL)
      }

    },

    parseMissingValueHandling = function(){
      if (hasField(self$mlTask$DataSpecification,"MissingValueHandling")){
        return (self$mlTask$DataSpecification$MissingValueHandling)}

      else{
        return (NULL)
      }
    },

    parsePlotting = function() {
      if (hasField(self$mlTask,"Plotting") && hasField(self$mlTask$Plotting,'Plot')){

        plotting <- list()

        for (variable in self$mlTask$Plotting){
          plotting$filename <- c(plotting$filename,variable$filename)
          plotting$type <- c(plotting$type,variable$PlotType)
        }

        return (as.data.frame(plotting))

      }else{
        return (NULL)
      }
    }

  ) # end private methods


) # end class


#' Convert machine learning task from XML to R
#'
#' Function parses an existing machine learning task from an XML file and trains the corresponding
#' dataset with \code{caret}.
#' @param path Path to XML file containing the task description.
#' @return An abstract representation of the task as defined by the XML file.
#' @examples
#' data(iris)
#'
#' # specify sample file
#' file <- system.file("XML", "iris_classification.xml", package = "mlLang")
#'
#' # read object in unified machine learning model
#' task <- parseMlTask(file)
#'
#' # train object with data
#' model <- executeMlTask(task, iris)
#'
#' summary(model)
#' @export
parseMlTask <- function(path) {
  return(ParsedMlTask$new(path))
}

#' Executes machine learning task to train a model
#'
#' Function takes an abstract definition of a machine learning task and a data object as input.
#' It then executes the training process and returns the trained object.
#' @param model Abstract machine learning task from loading an XML file.
#' @param data Data object used for training.
#' @param logger Specifies a function for logging. By default, the process is written to
#' the screen. By setting to \code{NULL}, output is disabled. When entering a filename, all
#' messages are written to the hard disk.
#' @return Trained object of class \code{train} as return by \code{\link[caret]{train}}.
#' @examples
#' library(e1071)
#'
#' data(iris)
#'
#' # specify sample file
#' file <- system.file("XML", "iris_classification.xml", package = "mlLang")
#'
#' # read object in unified machine learning model
#' task <- parseMlTask(file)
#'
#' # train object with data
#' model <- executeMlTask(task, iris)
#'
#' summary(model)
#' @export
executeMlTask <- function(model, data, logger = cat) {
  return(model$executeMlTask(data, logFunction(logger)))
}

logFunction <- function(obj) {
  if (is.null(obj)) {
    return(function(...) {})
  } else if (is.character(obj)) {
   return(function(...) { do.call(cat, list(..., "\n", file = obj))})
  } else
  {
    return(function(...) { do.call(obj, list(..., "\n"))})
  }
}

#' Execute a collection of machine learning tasks
#'
#' Function executes and trains a collection of machine learning tasks.
#' @param files Collection of file names to specify XML files containing task in
#' unified machine learning language.
#' @param data Data object used for training.
#' @param logger Specifies a function for logging. By default, the process is written to
#' the screen. By setting to \code{NULL}, output is disabled. When entering a filename, all
#' messages are written to the hard disk.
#' @return List of trained object of class \code{train} as return by
#' \code{\link[caret]{train}}.
#' @examples
#' library(e1071)
#'
#' data(iris)
#'
#' files <- list.files(system.file("XML", package = "mlLang"),
#'                     pattern = "iris_classification(.*).xml",
#'                     full.names = TRUE)
#'
#' models <- runMlTasks(files, iris)
#' @export
runMlTasks <- function(files, data, logger = cat) {
  if (length(files) == 0)
    stop("No entries in 'files'.")

  return(lapply(files,
                parseExecuteMlTask,
                data = data,
                logger = logger))
}

#' Schedules a collection of machine learning tasks for batch processing
#'
#' Function executes and trains a collection of machine learning tasks. It utilizes the
#' batch processing from the package \code{BatchJobs}.
#' @param reg Registry of batch job.
#' @param files Collection of file names to specify XML files containing task in
#' unified machine learning language.
#' @param data Data object used for training.
#' @param logger Specifies a function for logging. By default, the process is written to
#' the screen. By setting to \code{NULL}, output is disabled. When entering a filename, all
#' messages are written to the hard disk.
#' @return Ids of batch jobs.
#' @examples
#' library(BatchJobs)
#'
#' data(iris)
#'
#' files <- list.files(system.file("XML", package = "mlLang"),
#'                     pattern = "iris_classification(.*).xml",
#'                     full.names = TRUE)
#'
#' reg <- makeRegistry(id = "mlLang")
#'
#' ids <- scheduleMlTasks(reg, files, iris)
#'
#' showStatus(reg)
#'
#' \dontrun{
#'   # retrieve result for first model once completed
#'   m1 <- loadResult(reg, 1)
#' }
#' @export
scheduleMlTasks <- function(reg, files, data, logger = NULL) {
  ids <- BatchJobs::batchMap(reg,
                             fun = parseExecuteMlTask,
                             files,
                             more.args = list(data = data, logger = logger))
  BatchJobs::submitJobs(reg)
  return(ids)
}

parseExecuteMlTask <- function(f, data, logger) {
  task <- parseMlTask(f)
  return(executeMlTask(task, data, logger))
}
