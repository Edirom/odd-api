# ODD API

[![Docker Cloud Automated build](https://img.shields.io/docker/cloud/automated/edirom/odd-api)](https://hub.docker.com/r/edirom/odd-api/)
[![Docker](https://github.com/Edirom/odd-api/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/Edirom/odd-api/actions/workflows/docker-publish.yml)

This is a small web application that provides information about an ODD (either TEI or MEI). At this point, it supports MEI 4.0.1 and TEI 4.3.0. 

The API offers the following endpoints: 

* `/mei/4.0.1/modules.json`
* `/mei/4.0.1/MEI.cmn/elements.json` 
* `/mei/4.0.1/MEI.cmn/attClasses.json`
* `/mei/4.0.1/bracketSpan/atts.json` 
 
It will return JSON with the corresponding information. The two folders (*mei* and *4.0.1*) reflect folders inside the */data* folder of the app. If you want to support additional, ODD-based formats, just put them in the appropriate folders and the app will pick them up.