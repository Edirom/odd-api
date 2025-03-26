xquery version "3.1";

(:
    getElementsByModule.xql
    
    This xQuery loads all elements contained in a given module
:)

import module namespace config="http://odd-api.edirom.de/xql/config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:media-type "application/json";
declare option output:method "json";

let $header-addition := response:set-header("Access-Control-Allow-Origin","*")

let $module := request:get-parameter('module','')
let $module.replaced := replace($module,'_','.')

let $odd.source := config:odd-source()

let $elements := 
    for $elem in $odd.source//tei:elementSpec[@module = ($module,$module.replaced)]
    let $ident := $elem/data(@ident)
    let $desc := ($elem/tei:desc[@xml:lang = config:docLang()], $elem/tei:desc)[1] => normalize-space()
    return 
        map {
            'name': $ident,
            'desc': $desc
        }
    
    

return
    array { $elements }

