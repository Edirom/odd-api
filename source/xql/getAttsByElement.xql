xquery version "3.1";

(:
    getAttsByElement.xql
    
    This xQuery loads all attributes available on a given element
:)

import module namespace config="http://odd-api.edirom.de/xql/config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace local="no:link";

declare option exist:serialize "method=json media-type=application/json";

declare function local:getIdentAndDesc($obj as node()) as map(*) {
    let $ident := $obj/data(@ident)
    let $desc := ($obj/tei:desc[@xml:lang = config:docLang()], $obj/tei:desc)[1] => normalize-space()
    return 
        map {
            'name': $ident,
            'desc': $desc
        }
};

declare function local:getDirectAtts($parent as node()) as map(*)* {
    $parent//tei:attDef ! local:getIdentAndDesc(.)
};

declare function local:getClasses($parent as node(),$odd.source as node()) as map(*) {
    
    let $directAtts := local:getDirectAtts($parent)
    
    let $memberClasses := 
        for $key in $parent/tei:classes/tei:memberOf/@key[starts-with(.,'att.')]
        let $class := $odd.source//tei:classSpec[@type = 'atts'][@ident = $key]
        return local:getClasses($class,$odd.source)
        
    let $type := substring-before(local-name($parent),'Spec')
    let $ident := $parent/data(@ident)
    let $module := $parent/data(@module)
    let $desc := ($parent/tei:desc[@xml:lang = config:docLang()], $parent/tei:desc)[1] => normalize-space()
    
    return
        map {
            'name': $ident,
            'desc': $desc,
            'module': $module,
            'atts': $directAtts,
            'classes': $memberClasses
        }
};

let $header-addition := response:set-header("Access-Control-Allow-Origin","*")

let $elem := request:get-parameter('element','')


let $odd.source := config:odd-source()
let $element := $odd.source//tei:elementSpec[@ident = $elem]

let $classes := local:getClasses($element,$odd.source)
    
    
return 
    $classes


