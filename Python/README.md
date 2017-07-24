

Unified Machine Learning Language (mlLang)
==========================================

**mlLang** takes hold of the Unified Machine Learning Language (mlLang) inside R and python. We have developed **mlLang** as an XML-based, unified language for machine learning. It standardizes all relevant steps to train superior models: preprocessing operations, model specification, and the tuning process. It thereby makes model tuning reproducible and documents the underlying process.

This package ships the converter for R and python. For this purpose, it implements converters in two directions. (1) It automatically reads files in the unified machine learning language from custom XML files and then constructs a corresponding machine learning model in R. (2) It also supports the other direction and automatically converts machine learning models into XML files according to the unified machine learning language. All machine learning models are built on top of "caret" and "sklearn".

Simply load **mlLang** when starting your programming session. Afterwards, all machine learning operations are recorded and written to the disk in an open XML format. This file can be later loaded to reproduce models and training processes from machine learning.

Overview
--------

The most important functions in **mlLang** are:

-   `TaskExecuter(xml_file, data, labels)` converts XML files written in the Unified Machine Learning Language into python objects. Afterwards, `train()` runs the corresponding training routines on the given data.

-   Additional function replace the training process for machine learning models in order to convert it into XML files following the Unified Machine Learning Language.

-   This package supports the main functionality as provided by the package `caret` and `sklearn` for machine learning in R and Python.

To see examples of these functions in use, check out the help pages, the demos and the vignette.

Installation
------------

Using the **devtools** package, you can easily install the latest development version of **mlLang** with

``` bash
pip install mlLang

```

Note: A CRAN version has not yet been released.

Usage
-----

This section shows the basic functionality of how to work with the Unified Machine Learning Language. First, load the corresponding package **mlLang**.

``` python
from mlLang.task_executer import TaskExecuter
from mlLang.parser import Parser
```

Parser: XML to R
----------------

The following code demonstrates some of the functionality provided by **mlLang**.

``` python
from sklearn import datasets
# sample data
iris = datasets.load_iris()
data = iris.data
labels = iris.target



# specify sample file
xml_input = 'example.xml'

# read task from unified machine learning language
executer = TaskExecuter(xml_input, data, labels)
# train object with data
executer.train()

#>Fold: 0
#>[{'maxTreeDepth': 1.0, 'minTerminalNodeSize': 1.0, 'numberTrees': 3.0, 'shrinkage': 0.2}, {'maxTreeDepth': 3.0, 'minTerminalNodeSize': 1.0, 'numberTrees': 3.0, 'shrinkage': 0.2}]
#>{'maxTreeDepth': 1.0, 'minTerminalNodeSize': 1.0, 'numberTrees': 3.0, 'shrinkage': 0.2}
#>{'maxTreeDepth': 3.0, 'minTerminalNodeSize': 1.0, 'numberTrees': 3.0, 'shrinkage': 0.2}
#>RMSE: 0.0
#>Fold: 1
#>[{'maxTreeDepth': 1.0, 'minTerminalNodeSize': 1.0, 'numberTrees': 3.0, 'shrinkage': 0.2}, {'maxTreeDepth': 3.0, 'minTerminalNodeSize': 1.0, 'numberTrees': 3.0, 'shrinkage': 0.2}]
#>{'maxTreeDepth': 1.0, 'minTerminalNodeSize': 1.0, 'numberTrees': 3.0, 'shrinkage': 0.2}
#>{'maxTreeDepth': 3.0, 'minTerminalNodeSize': 1.0, 'numberTrees': 3.0, 'shrinkage': 0.2}
#>RMSE: 0.0
#>Fold: 2
#>[{'maxTreeDepth': 1.0, 'minTerminalNodeSize': 1.0, 'numberTrees': 3.0, 'shrinkage': 0.2}, {'maxTreeDepth': 3.0, 'minTerminalNodeSize': 1.0, 'numberTrees': 3.0, 'shrinkage': 0.2}]
#>{'maxTreeDepth': 1.0, 'minTerminalNodeSize': 1.0, 'numberTrees': 3.0, 'shrinkage': 0.2}
#>{'maxTreeDepth': 3.0, 'minTerminalNodeSize': 1.0, 'numberTrees': 3.0, 'shrinkage': 0.2}
#>RMSE: 0.31622776601683794
#>Fold: 3
#>[{'maxTreeDepth': 1.0, 'minTerminalNodeSize': 1.0, 'numberTrees': 3.0, 'shrinkage': 0.2}, {'maxTreeDepth': 3.0, 'minTerminalNodeSize': 1.0, 'numberTrees': 3.0, 'shrinkage': 0.2}]
#>{'maxTreeDepth': 1.0, 'minTerminalNodeSize': 1.0, 'numberTrees': 3.0, 'shrinkage': 0.2}
#>{'maxTreeDepth': 3.0, 'minTerminalNodeSize': 1.0, 'numberTrees': 3.0, 'shrinkage': 0.2}
#>RMSE: 0.2581988897471611
#>Fold: 4
#>[{'maxTreeDepth': 1.0, 'minTerminalNodeSize': 1.0, 'numberTrees': 3.0, 'shrinkage': 0.2}, {'maxTreeDepth': 3.0, 'minTerminalNodeSize': 1.0, 'numberTrees': 3.0, 'shrinkage': 0.2}]
#>{'maxTreeDepth': 1.0, 'minTerminalNodeSize': 1.0, 'numberTrees': 3.0, 'shrinkage': 0.2}
#>{'maxTreeDepth': 3.0, 'minTerminalNodeSize': 1.0, 'numberTrees': 3.0, 'shrinkage': 0.2}
#>RMSE: 0.4472135954999579
#>Average Results 0.20432805025279138

```

XML syntax of the Unified Machine Learning Language
---------------------------------------------------

``` python
parser = Parser()
parser.validate(xml_input)
#>XML file was parsed without errors
#>True
```

License
-------

**mlLang** is released under the [MIT License](https://opensource.org/licenses/MIT)

Copyright (c) 2016 Andreas Frorath & Stefan Feuerriegel