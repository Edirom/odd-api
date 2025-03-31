xquery version "3.1";

module namespace config="http://odd-api.edirom.de/xql/config";

declare namespace repo="http://exist-db.org/xquery/repo";
declare namespace expath="http://expath.org/ns/pkg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace system="http://exist-db.org/xquery/system";
declare namespace tei="http://www.tei-c.org/ns/1.0";

(: 
    Determine the application root collection from the current module load path.
:)
declare variable $config:app-root := 
    let $rawPath := system:get-module-load-path()
    let $modulePath :=
        (: strip the xmldb: part :)
        if (starts-with($rawPath, "xmldb:exist://")) then
            if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
                substring($rawPath, 36)
            else
                substring($rawPath, 15)
        else
            $rawPath
    return
        substring-before($modulePath, "/resources/xql")
;

declare variable $config:data-root := $config:app-root || "/data";

declare variable $config:repo-descriptor := doc(concat($config:app-root, "/repo.xml"))/repo:meta;

declare variable $config:expath-descriptor := doc(concat($config:app-root, "/expath-pkg.xml"))/expath:package;

(: maximum for the limit parameter :)
declare variable $config:max-limit := 200;

(:~
 :  Grab the ODD source
 :)
declare function config:odd-source() as element(tei:TEI) {
    let $format := request:get-parameter('format','')
    let $version := request:get-parameter('version','')
    return
        collection(string-join(($config:data-root, $format, $version), '/'))//tei:TEI
};

(:~
 :  The requested "documentation language" (per URL parameter). 
 :  It specifies which language to use when 
 :  creating documentation if the description for an element, attribute, class 
 :  or macro is available in more than one language.
 :  See https://www.tei-c.org/release/doc/tei-p5-doc/en/html/ref-schemaSpec.html
 :)
declare function config:docLang() as xs:string {
    request:get-parameter('docLang','')
};
