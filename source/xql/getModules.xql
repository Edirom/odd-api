xquery version "3.0";

(:
    getModules.xql
    
    This xQuery retrieves all module names in an ODD file
    $param: 
:)

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace response="http://exist-db.org/xquery/response"; 

declare option exist:serialize "method=xml media-type=text/plain omit-xml-declaration=yes indent=yes";

let $header-addition := response:set-header("Access-Control-Allow-Origin","*")

let $data.basePath := '/db/apps/odd-api/data'

let $format := request:get-parameter('format','')
let $version := request:get-parameter('version','')

let $path := $data.basePath || '/' || $format || '/' || $version

let $odd.source := collection($path)//tei:TEI

let $modules := 
    for $module in $odd.source//tei:moduleSpec
    let $ident := $module/@ident
    let $desc := $module/tei:desc/text()
    let $elementCount := count($odd.source//tei:elementSpec[@module = $ident])
    let $attClassCount := count($odd.source//tei:classSpec[@type = 'atts' and @module = $ident])
    return '{' ||
        '"name":"' || $ident || '",' ||
        '"desc":"' || $desc || '",' ||
        '"elementCount":"' || $elementCount || '",' ||
        '"attClassCount":"' || $attClassCount || '"' ||
        '}'
    
    
return 
    '[' || string-join($modules,',') || ']'


