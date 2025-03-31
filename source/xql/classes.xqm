xquery version "3.1";

module namespace classes="http://odd-api.edirom.de/xql/classes";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace rest="http://exquery.org/ns/restxq";
declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace common="http://odd-api.edirom.de/xql/common" at "common.xqm";

declare
    %rest:GET
    %rest:path("/v1/{$schema}/{$version}/{$module}/attClasses.json")
    %rest:produces("application/json")
    %rest:query-param("docLang", "{$docLang}", "en")
    %output:media-type("application/json")
    %output:method("json")
    function classes:attClasses-v1(
        $schema as xs:string, $version as xs:string,
        $module as xs:string, $docLang as xs:string*
        ) {
            $common:response-headers,
            classes:get-attClasses-v1($schema, $version, $module, $docLang[1])
};

declare %private function classes:get-attClasses-v1(
    $schema as xs:string, $version as xs:string,
    $module as xs:string, $docLang as xs:string
    ) as array(*) {
        let $odd.source := common:odd-source($schema, $version)
        let $module.replaced := replace($module,'_','.')
        let $classes :=
            for $class in $odd.source//tei:classSpec[@module = ($module, $module.replaced)][@type = 'atts']
            let $spec-basic-data := common:get-spec-basic-data($class, $docLang)
            return
                map {
                    'name': $spec-basic-data?ident,
                    'desc': $spec-basic-data?desc
                }
        return
            array { $classes } => array:sort((), function($class) {$class?name})
};

declare function classes:get-attribute-classes-recursively-v1(
    $spec as element(), $odd.source as element(tei:TEI),
    $docLang as xs:string
    ) as array(*) {
        let $memberClasses :=
            for $key in $spec/tei:classes/tei:memberOf/@key[starts-with(.,'att.')]
            let $class := $odd.source//tei:classSpec[@type = 'atts'][@ident = $key]
            let $directAtts := common:get-direct-attributes-v1($class, $docLang)
            let $spec-basic-data := common:get-spec-basic-data($class, $docLang)
            return
                map {
                    'name': $spec-basic-data?ident,
                    'desc': $spec-basic-data?desc,
                    'module': $spec-basic-data?module,
                    'atts': $directAtts,
                    'classes': classes:get-attribute-classes-recursively-v1($class, $odd.source, $docLang)
                }
        return
            array { $memberClasses } => array:sort((), function($class) {$class?name})
};
