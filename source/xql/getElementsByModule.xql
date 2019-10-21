xquery version "3.1";

(:
    getElementsByModule.xql
    
    This xQuery loads all elements contained in a given module
:)

import module namespace config="http://odd-api.edirom.de/xql/config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace response="http://exist-db.org/xquery/response"; 

declare option exist:serialize "method=json media-type=application/json";

let $header-addition := response:set-header("Access-Control-Allow-Origin","*")

let $module := request:get-parameter('module','')
let $module.replaced := replace($module,'_','.')

let $path := $data.basePath || '/' || $format || '/' || $version

let $odd.source := config:odd-source()

let $elements := 
    for $elem in $odd.source//tei:elementSpec[@module = ($module,$module.replaced)]
    let $ident := $elem/data(@ident)
    let $desc := $elem/tei:desc => normalize-space()
    return 
        map {
            'name': $ident,
            'desc': $desc
        }
    
    
return 
    [$elements]


