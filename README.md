Unified Machine Learning Language (mlLang)
==========================================

**mlLang** takes hold of the Unified Machine Learning Language (mlLang) inside R. We have developed **mlLang** as an XML-based, unified language for machine learning. It standardizes all relevant steps to train superior models: preprocessing operations, model specification, and the tuning process. It thereby makes model tuning reproducible and documents the underlying process.

**mlLang** ships the converters for different programming language. For this purpose, it implements converters in two directions. 

(1) It automatically reads files in the unified machine learning language from custom XML files and then constructs a corresponding machine learning model in a given programming language. 

(2) It also supports the other direction and automatically converts machine learning models into XML files according to the unified machine learning language. 

Supported Languages
-------

Currently, the following languages are supported:

* [**R**](https://github.com/sfeuerriegel/mllang/tree/master/R):  Simply load [**mlLang for R**](https://github.com/sfeuerriegel/mllang/tree/master/R) when starting your programming session. Afterwards, the machine learning operations from caret are recorded and written to the disk in an open XML format. This file can be later loaded to reproduce models and training processes from machine learning. 

* **Python**: A Python variant for scikit-learn is currently in development.

License
-------

**mlLang** is released under the [MIT License](https://opensource.org/licenses/MIT)

Copyright (c) 2017 Stefan Feuerriegel