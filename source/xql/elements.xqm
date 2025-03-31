xquery version "3.1";

module namespace elements="http://odd-api.edirom.de/xql/elements";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace rest="http://exquery.org/ns/restxq";
declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace common="http://odd-api.edirom.de/xql/common" at "common.xqm";
import module namespace classes="http://odd-api.edirom.de/xql/classes" at "classes.xqm";

declare
    %rest:GET
    %rest:path("/v1/{$schema}/{$version}/{$module}/elements.json")
    %rest:produces("application/json")
    %rest:query-param("docLang", "{$docLang}", "en")
    %output:media-type("application/json")
    %output:method("json")
    function elements:elements-v1(
        $schema as xs:string, $version as xs:string,
        $module as xs:string, $docLang as xs:string*
        ) {
            $common:response-headers,
            elements:get-elements-v1($schema, $version, $module, $docLang[1])
};

declare
    %rest:GET
    %rest:path("/v1/{$schema}/{$version}/{$element}/atts.json")
    %rest:produces("application/json")
    %rest:query-param("docLang", "{$docLang}", "en")
    %output:media-type("application/json")
    %output:method("json")
    function elements:element-attributes-v1(
        $schema as xs:string, $version as xs:string,
        $element as xs:string, $docLang as xs:string*
        ) {
            $common:response-headers,
            elements:get-element-attributes-v1($schema, $version, $element, $docLang[1])
};


declare %private function elements:get-elements-v1(
    $schema as xs:string, $version as xs:string,
    $module as xs:string, $docLang as xs:string
    ) as array(*) {
        let $odd.source := common:odd-source($schema, $version)
        let $module.replaced := replace($module,'_','.')
        let $elements :=
            for $elem in $odd.source//tei:elementSpec[@module = ($module, $module.replaced)]
            let $spec-basic-data := common:get-spec-basic-data($elem, $docLang)
            return
                map {
                    'name': $spec-basic-data?ident,
                    'desc': $spec-basic-data?desc
                }
        return
            array { $elements } => array:sort((), function($elem) {$elem?name})
};

declare %private function elements:get-element-attributes-v1(
    $schema as xs:string, $version as xs:string,
    $element as xs:string, $docLang as xs:string
    ) as map(*) {
        let $odd.source := common:odd-source($schema, $version)
        let $elem := $odd.source//tei:elementSpec[@ident = $element]
        let $spec-basic-data := common:get-spec-basic-data($elem, $docLang)
        let $direct-attributes := common:get-direct-attributes-v1($elem, $docLang)
        return
            map {
                'name': $spec-basic-data?ident,
                'desc': $spec-basic-data?desc,
                'module': $spec-basic-data?module,
                'atts': $direct-attributes,
                'classes': classes:get-attribute-classes-recursively-v1($elem, $odd.source, $docLang)
            }
};
