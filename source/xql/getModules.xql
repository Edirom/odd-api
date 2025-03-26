xquery version "3.1";

(:
    getModules.xql
    
    This xQuery retrieves all module names in an ODD file
    $param: 
:)

import module namespace config="http://odd-api.edirom.de/xql/config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:media-type "application/json";
declare option output:method "json";

let $header-addition := response:set-header("Access-Control-Allow-Origin","*")

let $odd.source := config:odd-source()

let $modules := 
    for $module in $odd.source//tei:moduleSpec
    let $ident := $module/data(@ident)
    let $desc := ($module/tei:desc[@xml:lang = config:docLang()], $module/tei:desc)[1] => normalize-space()
    let $elementCount := count($odd.source//tei:elementSpec[@module = $ident])
    let $attClassCount := count($odd.source//tei:classSpec[@type = 'atts'][@module = $ident])
    return
        map {
            'name': $ident,
            'desc': $desc,
            'elementCount': $elementCount,
            'attClassCount': $attClassCount
        }

return 
    array { $modules }
