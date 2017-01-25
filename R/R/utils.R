listToXML <- function(node, sublist){
  # Transformes a list to xml and appends it to the given node

  for (i in 1:length(sublist)) {
    child <- XML::newXMLNode(names(sublist)[i], parent=node);

    if (typeof(sublist[[i]]) == "list") {
      listToXML(child, sublist[[i]])
    } else {
      XML::xmlValue(child) <- sublist[[i]]
    }
  }

}

hasField <- function(dataFrame, field) {
  return(field %in% names(dataFrame))
}

listToString <- function(l) {
  do.call(paste0, list(unlist(lapply(1:length(l), function(i) paste0(names(l)[i], "=", l[[i]]))), collapse = ";"))
}
