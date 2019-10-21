xquery version "3.0";

(:
    getAttsByElement.xql
    
    This xQuery loads all attributes available on a given element
:)

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace local="no:link";

declare option exist:serialize "method=xml media-type=text/javascript omit-xml-declaration=yes indent=yes";

declare function local:getIdentAndDesc($obj as node()) as xs:string {
    let $ident := $obj/@ident
    let $desc := replace(normalize-space(string-join($obj/tei:desc//text(),' ')),'"','&apos;')
    return 
        '{' ||
            '"name":"' || $ident || '",' ||
            '"desc":"' || $desc || '"' ||
        '}'
};

declare function local:getDirectAtts($parent as node()) as xs:string {
    let $attDefs := 
        for $attDef in $parent//tei:attDef
        return local:getIdentAndDesc($attDef)
    return 
        '[' ||
        string-join($attDefs,',') ||
        ']'
};

declare function local:getClasses($parent as node(),$odd.source as node()) as xs:string {
    
    let $directAtts := local:getDirectAtts($parent)
    
    let $memberClasses := 
        for $key in $parent/tei:classes/tei:memberOf/@key[starts-with(.,'att.')]
        let $class := $odd.source//tei:classSpec[@type = 'atts' and @ident = $key]
        return local:getClasses($class,$odd.source)
        
    let $type := substring-before(local-name($parent),'Spec')
    let $ident := $parent/@ident
    let $module := $parent/@module
    let $desc := replace(normalize-space(string-join($parent/tei:desc//text(),' ')),'"','&apos;')
    
    return 
        '{' ||
            '"name":"' || $ident || '",' ||
            '"desc":"' || $desc || '",' ||
            '"module":"' || $module || '",' ||
            '"atts":' || $directAtts || ',' ||
            '"classes":[' || string-join($memberClasses,',') || ']' ||
        '}'
};

let $header-addition := response:set-header("Access-Control-Allow-Origin","*")

let $data.basePath := '/db/apps/odd-api/data'

let $format := request:get-parameter('format','')
let $version := request:get-parameter('version','')
let $elem := request:get-parameter('element','')

let $path := $data.basePath || '/' || $format || '/' || $version

let $odd.source := collection($path)//tei:TEI
let $element := $odd.source//tei:elementSpec[@ident = $elem]

let $classes := local:getClasses($element,$odd.source)
    
    
return 
    $classes


