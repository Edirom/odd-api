# ODD API

This is a small web application that provides information about an ODD (either TEI or MEI). At this point, it supports MEI 4.0.1 only. 

The API offers the following endpoints: 

*http://sample.net*/odd-api/mei/4.0.1/modules.json

*http://sample.net*/odd-api/mei/4.0.1/MEI.cmn/elements.json

*http://sample.net*/odd-api/mei/4.0.1/MEI.cmn/attCLasses.json

*http://sample.net*/odd-api/mei/4.0.1/bracketSpan/atts.json
 
It will return JSON with the corresponding information. The two folders (*mei* and *4.0.1*) reflect folders inside the */data* folder of the app. If you want to support additional, ODD-based formats, just put them in the appropriate folders and the app will pick them up.