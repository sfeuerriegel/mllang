#' Checks existing task file
#'
#' This routine checks if an existing XML task file adheres to the schema of the
#' unified machine learning language.
#' @param path Path to XML file
#' @return Returns \code{TRUE} if format is correct; otherwise \code{FALSE}.
#' @examples
#' file_correct <- system.file("XML", "iris_classification.xml", package = "mlLang")
#' checkSchema(file_correct) # should work correctly
#'
#' file_error <- system.file("XML", "iris_error.xml", package = "mlLang")
#' checkSchema(file_error) # should give a warning
#' @export
checkSchema <- function(path) {
  XMLSchemaPath <- system.file("XSD", "MLTask.xsd", package = "mlLang")

  return(validateXML(path, XMLSchemaPath))
}

validateXML <-  function(path_to_xml, path_to_xsd) {

  # Load and validate xml file according to the schema
  xsd <- XML::xmlTreeParse(path_to_xsd, isSchema = TRUE, useInternal = TRUE)
  doc <- XML::xmlInternalTreeParse(path_to_xml)
  validateResults <- XML::xmlSchemaValidate(xsd, doc)

  # Check if there are any errors
  if (validateResults$status == 0) {
    return(TRUE)
  } else {
    # Print errors
    cat("Mode file does not satisfy XML schema:\n")

    for (error in validateResults$errors) {
      cat("* Error in line ", error$line,": ", error$msg, "\n")
    }

    return (FALSE)
  }
}
