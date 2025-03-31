xquery version "3.1";

module namespace modules="http://odd-api.edirom.de/xql/modules";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace rest="http://exquery.org/ns/restxq";
declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace common="http://odd-api.edirom.de/xql/common" at "common.xqm";
import module namespace config="http://odd-api.edirom.de/xql/config" at "config.xqm";

declare
    %rest:GET
    %rest:path("/v1/{$schema}/{$version}/modules.json")
    %rest:produces("application/json")
    %rest:query-param("docLang", "{$docLang}", "en")
    %output:media-type("application/json")
    %output:method("json")
    function modules:modules-v1($schema as xs:string, $version as xs:string, $docLang as xs:string*) {
        $common:response-headers,
        modules:get-modules-v1($schema, $version, $docLang[1])
};


declare %private function modules:get-modules-v1($schema as xs:string, $version as xs:string, $docLang as xs:string) as array(*) {
    let $odd-source := common:odd-source($schema, $version)
    let $modules :=
        for $module in $odd-source//tei:moduleSpec
        let $spec-basic-data := common:get-spec-basic-data($module, $docLang)
        let $elementCount := count($odd-source//tei:elementSpec[@module = $spec-basic-data?ident])
        let $attClassCount := count($odd-source//tei:classSpec[@type = 'atts'][@module = $spec-basic-data?ident])
        return
            map {
                'name': $spec-basic-data?ident,
                'desc': $spec-basic-data?desc,
                'elementCount': $elementCount,
                'attClassCount': $attClassCount
            }
    return
        array { $modules } => array:sort((), function($module) {$module?name})
};
