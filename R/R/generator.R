#' Generation of unified machine learning language
#'
#' R6 class for converting a machine learning task to an XML file.
#' @format An \code{\link{R6Class}} generator object
#' @keywords internal
#' @docType class
#' @export
MlTaskGenerator <- R6Class("MlTaskGenerator",

  #public attributes and methods
  public = list(

    #attributes
    supported_preprocesssing = c("center", "scale", "YeoJohnson"),
    supported_metrics = c("ROC","Accuracy","RMSE","Kappa","Rsquared"),
    MlTask = list(),
    MlTask_as_XML = NULL,

    #constructor
    initialize = function() {
        MlTask <- list()
    },

    #methods

    #overwriting of caret function createDataPartition
    createDataPartition = function(y, times = 1, p = 0.5, list = TRUE, groups = min(5, length(y))){

      #add datasplit parameter to MlTask list
      self$MlTask$Evaluation$DataSplit <- list("partitionRate" = toString(p))

      return(caret::createDataPartition(y, times, p, list, groups))
    },

    #overwriting of caret function train
    train = function(x, y,
                      y_name, method = "rf", preProcess = NULL,
                      ...,
                      weights = NULL, metric = ifelse(is.factor(y), "Accuracy", "RMSE"),
                      maximize = ifelse(metric %in% c("RMSE", "logLoss"), FALSE, TRUE),
                      trControl = trainControl(), tuneGrid = NULL, tuneLength = 3) {

      #add parameters of train to MlTask list
      private$addPredictedVariable(y_name,y)
      private$addPredictors(x)
      private$addPreprossing(preProcess)
      private$addResampling(trControl)

      # train the model
      fitModel <- caret::train(x = x, y = y, method = method, preProcess = preProcess,
                        ... = ...,
                        weights = weights, metric = metric, maximize = maximize,
                        trControl = trControl,
                        tuneGrid = tuneGrid,
                        tuneLength = tuneLength)

      #add the used method and used tuning parameters to MlTask list
      private$addMethod(fitModel)
      private$addMetric(fitModel)

      return (fitModel)
    },

    print = function() {
      return(private$toXML())
    },

    write = function(filename, ...) {
      XML::saveXML(private$toXML(), filename)
      return()
    }

  ), # end public methods

  # private attributes and methods
  private = list(

    #methods

    addPredictedVariable = function(y_name,y) {
      predictedVariable <- list(name = y_name,VariableType = class(y))
      self$MlTask$DataSpecification$predictedVariable <- predictedVariable
    },

    addPredictors = function(x) {
      predictors <- list()

      for (predictor_name in rev(names(x))){

        #forcing structure $predictor$name for all predictors by overwriting an concatenation with previous copy
        predictors_buf = predictors

        predictors <- list()
        predictors$predictor$name <- predictor_name
        predictors$predictor$VariableType <- class(x[[predictor_name]])

        predictors <- c(predictors,predictors_buf)
      }

      self$MlTask$DataSpecification$Predictors <- predictors

    },

    addPreprossing = function(preProcess){
      if (!is.null(preProcess)) {
        preProcessMethods <- list()

        #Iterate over all possible preprocessing methods
        for (method in preProcess) {
          if (method %in% self$supported_preprocesssing){
            preProcessMethods <- c(preProcessMethods, "PreprocessMethod" = method)
          } else {
            warning(paste0(method, " not supported for XML generation"))
          }
        }

        if (length(preProcessMethods) > 0){
          self$MlTask$Preprocessing <- preProcessMethods
        }

      }
    },

    addResampling = function(trControl) {
      resampling <- list()
      method <- trControl$method

      if (method =="repeatedcv") {
        params <- list(numberSubsets = trControl$number, repeats = trControl$repeats)
        resampling$CrossValidation <- params
      }
      if (method =="cv") {
        params <- list(numberSubsets = trControl$number,repeats = 1)
        resampling$CrossValidation <- params
      }
      if (method =="boot") {
        params <- list(number = trControl$number)
        resampling$Bootstrap <- params
      }

      if (length(resampling) > 0) {
        self$MlTask$Evaluation$Resampling <- resampling
      } else {
        warning(paste0(method, " resampling not supported for XML generation"))
      }
    },

    extractTuningParameters = function(fitModel, tuningParameterName){
      tuningParameters <- list()
      uniqueValues <- unique(fitModel$result[[tuningParameterName]])

      for (value in uniqueValues) {
        tuningParameters <- c(tuningParameters, "value" = value)
      }

      return (tuningParameters)
    },

    addMethod = function(fitModel) {

      method_caret <- fitModel$method
      method <- list()

      if (method_caret == "gbm") {
        params <- list()
        params$numberTrees <- private$extractTuningParameters(fitModel, "n.trees")
        params$maxTreeDepth <- private$extractTuningParameters(fitModel, "interaction.depth")
        params$shrinkage <- private$extractTuningParameters(fitModel, "shrinkage")
        params$minTerminalNodeSize <- private$extractTuningParameters(fitModel,"n.minobsinnode")

        method$StochasticGradientBoosting <- params
      }

      if (method_caret =="lm") {
        params <- list()
        params$intercept <- private$extractTuningParameters(fitModel, "intercept")

        method$LinearRegression <- params
      }

      if (method_caret == "mlpWeightDecay") {
        params <- list()
        params$hiddenUnits <- private$extractTuningParameters(fitModel, "size")
        params$weightDecay <- private$extractTuningParameters(fitModel, "decay")

        method$MultiLayerPerceptron <- params
      }

      if (method_caret =="ranger"){
        params <- list()
        params$randomlySelectedPredictors <- private$extractTuningParameters(fitModel,'mtry')

        method$RandomForest <- params
      }

      if (method_caret =="rpart"){
        params <- list()
        params$complexityParameter <- private$extractTuningParameters(fitModel,'cp')

        method$CART <- params
      }

      if (method_caret =="svmLinear"){
        params <- list()
        params$cost = private$extractTuningParameters(fitModel,'C')

        method$LinearSVM <- params
      }


      if(length(method)>0){
        self$MlTask$Method <- method
      }

      else {
        warning(paste0("Method ", method, " is not supported for XML generation"))
      }
    },

    #writes the internal MlTask to a xml file
    toXML = function() {

      self$MlTask_as_XML <- XML::newXMLNode("Task",
                                            attrs = c("xsi:noNamespaceSchemaLocation" = "MlTask.xsd"),
                                            namespaceDefinitions = c(xsi = "http://www.w3.org/2001/XMLSchema-instance"))

      listToXML(self$MlTask_as_XML, self$MlTask)
      return(self$MlTask_as_XML)
    },


    addMetric = function(fitModel){
      metric <- fitModel$metric

      if (metric %in% self$supported_metrics){
        self$MlTask$Evaluation$Metric <- fitModel$metric

      }else{
        print(paste(c(metric, "as metric not supported for XML generation"),collapse =" "))
      }
    }

  ) # end private methods

) # end class

#' Creates new machine learning task for export
#'
#' Initializes a new task for machine learning and
#' @return New object with empty task
#' @export
newMlTask <- function() {
  return(MlTaskGenerator$new())
}

#' Prints existing task object
#'
#' Writes XML of an existing machine learning task to the console. Output is in
#' unified machine learning language.
#' @param x Object of class \code{MlTaskGenerator}.
#' @param ... Option parameters (ignored).
#' @return XML code of task object.
#' @export
print.MlTaskGenerator <- function(x, ...) {
  x$print()
}

#' Writes existing task object as XML to the disk
#'
#' Writes XML of an existing machine learning task to the disk. Output is in
#' unified machine learning language.
#' @param x Object of class \code{MlTaskGenerator}.
#' @param file Filename of object.
#' @param ... Optional arguments passed on to \code{\link[base]{write}}.
#' @export
#' @rdname write
write.MlTaskGenerator <- function(x, file = NULL, ...) {
  if (is.null(file)) {
    stop("Argument 'file' must be a filename.")
  }

  x$write(file, ...)
  return()
}

#' @export
#' @rdname write
write <- function(x, ...) {
  if ("MlTaskGenerator" %in% class(x)) {
    write.MlTaskGenerator(x, ...)
  } else {
    base::write(x, ...)
  }
  return()
}




