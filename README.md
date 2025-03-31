# ODD API

[![Docker](https://github.com/Edirom/odd-api/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/Edirom/odd-api/actions/workflows/docker-publish.yml)

This is a small web application that provides information about an ODD 
(either TEI or MEI).  

The API offers the following endpoints:

* `/v1/{mei|tei}/{$version}/modules.json`
* `/v1/{mei|tei}/{$version}/{$module}/elements.json`
* `/v1/{mei|tei}/{$version}/{$module}/attClasses.json`
* `/v1/{mei|tei}/{$version}/{$elementname}/atts.json`

Some examples for MEI:

* `/v1/mei/5.0/modules.json`
* `/v1/mei/4.0.1/modules.json`
* `/v1/mei/5.0/MEI.cmn/elements.json` 
* `/v1/mei/5.0/MEI.cmn/attClasses.json`
* `/v1/mei/4.0.1/bracketSpan/atts.json` 

… and for TEI:

* `/v1/tei/4.8.0/modules.json`
* `/v1/tei/4.8.0/header/elements.json`
* `/v1/tei/4.8.0/header/attClasses.json`
* `/v1/tei/4.8.0/abbr/atts.json`

It will return JSON with the corresponding information. If 
you want to support additional, ODD-based formats, just create the 
appropriate directory structure under `data`, build the app via `docker 
build -t my-odd-api .`, and the app will pick them up.
