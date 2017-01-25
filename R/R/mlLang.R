#' mlLang: A package for using the Unified Machine Learning Language from R
#'
#' The \code{mlLang} package brings the Unified Machine Learning Language (mlLang)
#' to R. It natively interacts with the automated training of machine learning
#' models using \code{caret}. For this purpose, it implements two ways
#' of interacting with mlLang. For one, it parses existing XML file written in
#' mlLang and runs the stored training processes. On the other hand, it captures
#' the training process from \code{caret} and stores it on the disk
#' as an XML file in mlLang syntax. This makes machine learning, and especially
#' the underlying tuning processes, reproducable and facilitates conversions
#' with other programs and languages.
#' @importFrom R6 R6Class
#' @import mlbench
#' @docType package
#' @name mlLang
NULL
