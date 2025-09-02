xquery version "3.1";

module namespace macros="http://odd-api.edirom.de/xql/macros";

declare namespace err="http://www.w3.org/2005/xqt-errors";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace req="http://exquery.org/ns/request";
declare namespace rest="http://exquery.org/ns/restxq";
declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace common="http://odd-api.edirom.de/xql/common" at "common.xqm";

declare
    %rest:GET
    %rest:path("/v2/{$schema}/{$version}/macros")
    %rest:query-param("docLang", "{$docLang}", "")
    %rest:query-param("module", "{$module}", "")
    %output:media-type("application/vnd.api+json")
    %output:method("json")
    function macros:get-macros($schema as xs:string, $version as xs:string, $docLang as xs:string*, $module as xs:string*) {
        try{
            $common:response-headers,
            macros:get-macros-shallow-list($schema, $version, $docLang, $module)
        }
        catch common:OddNotFoundError {
            common:set-status($common:response-headers, 404),
            common:json-api-error-object(
                $err:description,
                common:build-absolute-uri(req:hostname#0, req:scheme#0, req:port#0, rest:uri()),
                404,
                $err:code
            )
        }
        catch * {
            common:set-status($common:response-headers, 404),
            common:json-api-error-object(
                $err:description,
                common:build-absolute-uri(req:hostname#0, req:scheme#0, req:port#0, rest:uri()),
                404,
                $err:code
            )
        }
};

declare %private function macros:get-macros-shallow-list(
    $schema as xs:string, $version as xs:string,
    $docLangParam as xs:string*, $moduleParam as xs:string*) as map(*) {
        let $odd-source := common:odd-source($schema, $version)
        let $docLang := common:extract-query-parameters($docLangParam)
        let $module := common:extract-query-parameters($moduleParam)
        let $macroSpecs := $odd-source//tei:macroSpec => common:filter-by-module($module)
        return
            map {
                'data': array {
                    for $macroSpec in $macroSpecs
                    let $basic-data := common:get-spec-basic-data($macroSpec, $docLang)
                    let $macroIdent := $macroSpec/data(@ident)
                    return
                        map {
                            'type': 'macros',
                            'id': common:encode-jsonapi-id($schema, $version, 'macros', $macroIdent),
                            'attributes': $basic-data,
                            'links': map { 'self': common:build-absolute-uri(req:hostname#0, req:scheme#0, req:port#0, (rest:base-uri(), 'v2', $schema, $version, 'macros', $macroIdent)) }
                        }
                } => array:sort((), function($obj) {$obj?attributes?ident}),
                'links': map { 'self': common:build-absolute-uri(req:hostname#0, req:scheme#0, req:port#0, rest:uri()) }
            }
};
