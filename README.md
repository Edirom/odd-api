# ODD API

[![Docker Cloud Automated build](https://img.shields.io/docker/cloud/automated/edirom/odd-api)](https://hub.docker.com/r/edirom/odd-api/)
[![Docker](https://github.com/Edirom/odd-api/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/Edirom/odd-api/actions/workflows/docker-publish.yml)

This is a small web application that provides information about an ODD 
(either TEI or MEI). At this point, it supports MEI 4.0.1 and TEI 4.5.0. 

The API offers the following endpoints:

* `/{mei|tei}/{$version}/modules.json`
* `/{mei|tei}/{$version}/{$classname}/elements.json`
* `/{mei|tei}/{$version}/{$classname}/attClasses.json`
* `/{mei|tei}/{$version}/{$elementname}/atts.json`

Some examples for MEI:

* `/mei/4.0.1/modules.json`
* `/mei/4.0.1/MEI.cmn/elements.json` 
* `/mei/4.0.1/MEI.cmn/attClasses.json`
* `/mei/4.0.1/bracketSpan/atts.json` 

… and for TEI:

* `/tei/4.5.0/modules.json`
* `/tei/4.5.0/header/elements.json`
* `/tei/4.5.0/header/attClasses.json`
* `/tei/4.5.0/abbr/atts.json`

It will return JSON with the corresponding information. If 
you want to support additional, ODD-based formats, just create the 
appropriate directory structure under `data`, build the app via `docker 
build -t my-odd-api .`, and the app will pick them up.
