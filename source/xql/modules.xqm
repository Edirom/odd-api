xquery version "3.1";

module namespace modules="http://odd-api.edirom.de/xql/modules";

declare namespace err="http://www.w3.org/2005/xqt-errors";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace rest="http://exquery.org/ns/restxq";
declare namespace req="http://exquery.org/ns/request";
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

declare
    %rest:GET
    %rest:path("/v2/{$schema}/{$version}/modules")
    %rest:produces("application/json")
    %rest:produces("application/vnd.api+json")
    %output:media-type("application/vnd.api+json")
    %output:method("json")
    function modules:modules-v2($schema as xs:string, $version as xs:string) {
        $common:response-headers,
        map {
            'data': modules:get-modules-v2($schema, $version),
            'links': map {
                'self': common:build-absolute-uri(req:hostname#0, req:scheme#0, req:port#0, rest:uri())
            }
        }
};

declare %private function modules:get-modules-v1($schema as xs:string, $version as xs:string, $docLang as xs:string) as array(*) {
    let $odd-source := common:odd-source($schema, $version)
    let $modules :=
        for $module in $odd-source//tei:moduleSpec
        let $spec-basic-data := common:get-spec-basic-data-v1($module, $docLang)
        let $elementCount := count($odd-source//tei:elementSpec[@module = $spec-basic-data?name])
        let $attClassCount := count($odd-source//tei:classSpec[@type = 'atts'][@module = $spec-basic-data?name])
        return
            map:merge((
                $spec-basic-data,
                map {
                    'elementCount': $elementCount,
                    'attClassCount': $attClassCount
                }
            ))
    return
        array { $modules } => array:sort((), function($module) {$module?name})
};

declare %private function modules:get-modules-v2($schema as xs:string, $version as xs:string) as array(*) {
    let $odd-source := common:odd-source($schema, $version)
    let $modules :=
        for $module in $odd-source//tei:moduleSpec
        let $spec-basic-data := common:get-spec-basic-data($module, 'en')
        let $elementCount := count($odd-source//tei:elementSpec[@module = $spec-basic-data?ident])
        let $attClassCount := count($odd-source//tei:classSpec[@type = 'atts'][@module = $spec-basic-data?ident])
        let $id := common:encode-jsonapi-id($schema, $version, 'modules', $spec-basic-data?ident)
        return
            map {
                'type': 'modules',
                'id': $id,
                'attributes': map {
                    'name': $spec-basic-data?ident,
                    'desc': $spec-basic-data?desc,
                    'elementCount': $elementCount,
                    'attClassCount': $attClassCount
                },
                "links": map {
                    "self": common:build-absolute-uri(req:hostname#0, req:scheme#0, req:port#0, rest:uri() || '/' || $id)
                }
            }
    return
        array { $modules } => array:sort((), function($module) {$module?id})
};
