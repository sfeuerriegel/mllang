
<!-- README.md is generated from README.Rmd. Please edit that file -->
Unified Machine Learning Language (mlLang)
==========================================

<!--
[![Build Status](https://travis-ci.org/sfeuerriegel/SentimentAnalysis.svg?branch=master)](https://travis-ci.org/sfeuerriegel/mlLang)
[![CRAN_Status_Badge](http://www.r-pkg.org/badges/version/mlLang)](https://cran.r-project.org/package=SentimentAnalysis)
[![Coverage Status](https://img.shields.io/codecov/c/github/sfeuerriegel/mlLang/master.svg)](https://codecov.io/github/sfeuerriegel/mlLang?branch=master)
-->
**mlLang** takes hold of the Unified Machine Learning Language (mlLang) inside R.

TODO: motivating text why we need this

Overview
--------

The most important functions in **mlLang** are:

-   `parseMlTask(path)` converts XML files written in the Unified Machine Learning Language into R objects. Afterwards, `executeMlTask(model, data)` runs the corresponding training routines on the given data.

-   Additional function replace the training process for machine learning models in order to convert it into XML files following the Unified Machine Learning Language.

-   This package supports the main functionality as provided by the package `caret` for machine learning in R.

To see examples of these functions in use, check out the help pages, the demos and the vignette.

Installation
------------

Using the **devtools** package, you can easily install the latest development version of **mlLang** with

``` r
install.packages("devtools")

# Option 1: download and install latest version from ‘GitHub’
# Not yet supported: devtools::install_github("sfeuerriegel/mlLang")

# Option 2: install directly from bundled archive
devtoos::install_local("mlLang_0.0.1.tar.gz")
```

Note: A CRAN version has not yet been released.

Usage
-----

This section shows the basic functionality of how to work with the Unified Machine Learning Language. First, load the corresponding package **mlLang**.

``` r
library(mlLang)
```

Parser: XML to R
----------------

The following code demonstrates some of the functionality provided by **mlLang**.

``` r
# sample data
data(iris)

# specify sample file
file <- system.file("XML", "iris_classification.xml", package = "mlLang")

# read task from unified machine learning language
task <- parseMlTask(file)

# train object with data
model <- executeMlTask(task, iris)
#> Parse XML file 
#> Data split: 
#> 0.5 
#> Preprocessings:  
#> center scale 
#> Validation parameters:  
#> method=repeatedcv;number=5;repeats=6 
#> Predictors:  Sepal.Length; Sepal.Width; Petal.Length; Petal.Width; 
#> Target:  Species 
#> Algorithm:  method=gbm;tuningparameters=c(1, 3, 4);tuningparameters=20;tuningparameters=c(0.2, 0.1);tuningparameters=10 
#> Splitting data 
#> Begin training
#> Loading required package: gbm
#> Loading required package: survival
#> Loading required package: lattice
#> Loading required package: splines
#> Loading required package: parallel
#> Loaded gbm 2.1.1
#> Loading required package: plyr
#> Loading required package: ggplot2
#> 
#> Attaching package: 'caret'
#> The following object is masked from 'package:survival':
#> 
#>     cluster
#> Stochastic Gradient Boosting 
#> 
#> 75 samples
#>  4 predictor
#>  3 classes: 'setosa', 'versicolor', 'virginica' 
#> 
#> Pre-processing: centered (4), scaled (4) 
#> Resampling: Cross-Validated (5 fold, repeated 6 times) 
#> Summary of sample sizes: 60, 60, 60, 60, 60, 60, ... 
#> Resampling results across tuning parameters:
#> 
#>   shrinkage  n.trees  Accuracy   Kappa    
#>   0.1        1        0.7933333  0.6900000
#>   0.1        3        0.8488889  0.7733333
#>   0.1        4        0.8577778  0.7866667
#>   0.2        1        0.8577778  0.7866667
#>   0.2        3        0.8911111  0.8366667
#>   0.2        4        0.8933333  0.8400000
#> 
#> Tuning parameter 'interaction.depth' was held constant at a value of
#>  20
#> Tuning parameter 'n.minobsinnode' was held constant at a value of 10
#> Accuracy was used to select the optimal model using  the largest value.
#> The final values used for the model were n.trees = 4, interaction.depth
#>  = 20, shrinkage = 0.2 and n.minobsinnode = 10. 
#> 0.1 0.1 0.1 0.2 0.2 0.2 1 3 4 1 3 4 0.7933333 0.8488889 0.8577778 0.8577778 0.8911111 0.8933333 0.6900000 0.7733333 0.7866667 0.7866667 0.8366667 0.8400000 
#> Predict test data 
#> 0.9733333 0.96

summary(model)
```

![](README-unnamed-chunk-4-1.png)

    #>                       var      rel.inf
    #> Petal.Length Petal.Length 1.000000e+02
    #> Sepal.Width   Sepal.Width 2.999076e-30
    #> Sepal.Length Sepal.Length 3.623126e-31
    #> Petal.Width   Petal.Width 0.000000e+00

### Simultaneous execution of multiple tasks

``` r
library(tidyverse)
#> Loading tidyverse: tibble
#> Loading tidyverse: tidyr
#> Loading tidyverse: readr
#> Loading tidyverse: purrr
#> Loading tidyverse: dplyr
#> Conflicts with tidy packages ----------------------------------------------
#> arrange():   dplyr, plyr
#> compact():   purrr, plyr
#> count():     dplyr, plyr
#> failwith():  dplyr, plyr
#> filter():    dplyr, stats
#> id():        dplyr, plyr
#> lag():       dplyr, stats
#> lift():      purrr, caret
#> mutate():    dplyr, plyr
#> rename():    dplyr, plyr
#> summarise(): dplyr, plyr
#> summarize(): dplyr, plyr

set.seed(0)
in_train <- createDataPartition(iris$Species, p = 0.8, list = FALSE)

files <- list.files(system.file("XML", package = "mlLang"), 
                    pattern = "iris_classification(.*).xml",
                    full.names = TRUE)
models <- runMlTasks(files, iris[in_train, ], logger = NULL)

# best model
perf <- unlist(lapply(models, 
                      function(m) {
                        pred <- predict(m, newdata = iris[-in_train, ] %>% dplyr::select(-Species))
                        cm <- confusionMatrix(pred, iris[-in_train, "Species"])
                        return(cm$overall[["Accuracy"]])
                      }))
basename(files[which.max(perf)])
#> [1] "iris_classification_bootstrap.xml"
```

### Batch execution

``` r
library(BatchJobs)
#> Loading required package: BBmisc
#> 
#> Attaching package: 'BBmisc'
#> The following objects are masked from 'package:dplyr':
#> 
#>     coalesce, collapse
#> Sourcing configuration file: 'C:/Users/bwpc/Documents/R/win-library/3.3/BatchJobs/etc/BatchJobs_global_config.R'
#> BatchJobs configuration:
#>   cluster functions: Interactive
#>   mail.from: 
#>   mail.to: 
#>   mail.start: none
#>   mail.done: none
#>   mail.error: none
#>   default.resources: 
#>   debug: FALSE
#>   raise.warnings: FALSE
#>   staged.queries: TRUE
#>   max.concurrent.jobs: Inf
#>   fs.timeout: NA

reg <- makeRegistry(id = "mlLang")
#> Creating dir: C:/Users/bwpc/Desktop/AndreasFrorath/Code/DSLCaret/mlLang-files
#> Saving registry: C:/Users/bwpc/Desktop/AndreasFrorath/Code/DSLCaret/mlLang-files/registry.RData
ids <- scheduleMlTasks(reg, files, iris)
#> Adding 2 jobs to DB.
#> Saving conf: C:/Users/bwpc/Desktop/AndreasFrorath/Code/DSLCaret/mlLang-files/conf.RData
#> Submitting 2 chunks / 2 jobs.
#> Cluster functions: Interactive.
#> Auto-mailer settings: start=none, done=none, error=none.
#> Writing 2 R scripts...
#> Loading registry: C:/Users/bwpc/Desktop/AndreasFrorath/Code/DSLCaret/mlLang-files/registry.RData
#> Loading conf:
#> 2016-12-11 17:18:17: Starting job on node BW-PC.
#> Auto-mailer settings: start=none, done=none, error=none.
#> Setting work dir: C:/Users/bwpc/Desktop/AndreasFrorath/Code/DSLCaret
#> ########## Executing jid=1 ##########
#> Timestamp: 2016-12-11 17:18:17
#> Setting seed: 984887756
#> Writing result file: C:/Users/bwpc/Desktop/AndreasFrorath/Code/DSLCaret/mlLang-files/jobs/01/1-result.RData
#> 2016-12-11 17:18:20: All done.
#> Setting work back to: C:/Users/bwpc/Desktop/AndreasFrorath/Code/DSLCaret
#> Memory usage according to gc:
#> Loading registry: C:/Users/bwpc/Desktop/AndreasFrorath/Code/DSLCaret/mlLang-files/registry.RData
#> Loading conf:
#> 2016-12-11 17:18:20: Starting job on node BW-PC.
#> Auto-mailer settings: start=none, done=none, error=none.
#> Setting work dir: C:/Users/bwpc/Desktop/AndreasFrorath/Code/DSLCaret
#> ########## Executing jid=2 ##########
#> Timestamp: 2016-12-11 17:18:20
#> Setting seed: 984887757
#> Writing result file: C:/Users/bwpc/Desktop/AndreasFrorath/Code/DSLCaret/mlLang-files/jobs/02/2-result.RData
#> 2016-12-11 17:18:21: All done.
#> Setting work back to: C:/Users/bwpc/Desktop/AndreasFrorath/Code/DSLCaret
#> Memory usage according to gc:
#> Sending 2 submit messages...
#> Might take some time, do not interrupt this!

showStatus(reg)
#> Syncing registry ...
#> Status for 2 jobs at 2016-12-11 17:18:21
#> Submitted: 2 (100.00%)
#> Started:   2 (100.00%)
#> Running:   0 (  0.00%)
#> Done:      2 (100.00%)
#> Errors:    0 (  0.00%)
#> Expired:   0 (  0.00%)
#> Time: min=1.00s avg=2.00s max=3.00s
```

``` r
# retrieve result for first model once completed
m1 <- loadResult(reg, 1)
```

Generator: R to XML
-------------------

``` r
set.seed(0)

data(iris)
predictors <- c("Sepal.Length", "Sepal.Width", "Petal.Length", "Petal.Width")

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

summary(model)
```

![](README-unnamed-chunk-8-1.png)

    #>                       var    rel.inf
    #> Petal.Length Petal.Length 81.3243434
    #> Petal.Width   Petal.Width 15.4038530
    #> Sepal.Width   Sepal.Width  2.4010636
    #> Sepal.Length Sepal.Length  0.8707399

    write(task, "iris_classification.xml")
    #> NULL
    unlink("iris_classification.xml")

XML syntax of the Unified Machine Learning Language
---------------------------------------------------

``` r
file_correct <- system.file("XML", "iris_classification.xml", package = "mlLang")
checkSchema(file_correct) # should work correctly
#> [1] TRUE

file_error <- system.file("XML", "iris_error.xml", package = "mlLang")
checkSchema(file_error) # should give a warning
#> Mode file does not satisfy XML schema:
#> * Error in line  7 :  Element 'Datadescription': This element is not expected. Expected is one of ( DataDescription, Evaluation, Preprocessing, MlAlgorithm ).
#> 
#> [1] FALSE
```

License
-------

**mlLang** is released under the [MIT License](https://opensource.org/licenses/MIT)

Copyright (c) 2016 Andreas Frorath & Stefan Feuerriegel
