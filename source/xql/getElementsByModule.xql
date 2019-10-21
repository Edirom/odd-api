xquery version "3.1";

(:
    getElementsByModule.xql
    
    This xQuery loads all elements contained in a given module
:)

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace response="http://exist-db.org/xquery/response"; 

declare option exist:serialize "method=json media-type=application/json";

let $header-addition := response:set-header("Access-Control-Allow-Origin","*")

let $data.basePath := '/db/apps/odd-api/data'

let $format := request:get-parameter('format','')
let $version := request:get-parameter('version','')
let $module := request:get-parameter('module','')
let $module.replaced := replace($module,'_','.')

let $path := $data.basePath || '/' || $format || '/' || $version

let $odd.source := collection($path)//tei:TEI

let $elements := 
    for $elem in $odd.source//tei:elementSpec[@module = ($module,$module.replaced)]
    let $ident := $elem/data(@ident)
    let $desc := replace(normalize-space(string-join($elem/tei:desc//text(),' ')),'"','&apos;')
    return 
        map {
            'name': $ident,
            'desc': $desc
        }
    
    
return 
    [$elements]


