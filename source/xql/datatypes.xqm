xquery version "3.1";

module namespace datatypes="http://odd-api.edirom.de/xql/datatypes";

declare namespace err="http://www.w3.org/2005/xqt-errors";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace req="http://exquery.org/ns/request";
declare namespace rest="http://exquery.org/ns/restxq";
declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace common="http://odd-api.edirom.de/xql/common" at "common.xqm";

declare
    %rest:GET
    %rest:path("/v2/{$schema}/{$version}/datatypes")
    %rest:query-param("docLang", "{$docLang}", "")
    %rest:query-param("module", "{$module}", "")
    %rest:produces("application/json")
    %rest:produces("application/vnd.api+json")
    %output:media-type("application/vnd.api+json")
    %output:method("json")
    function datatypes:get-datatypes($schema as xs:string, $version as xs:string, $docLang as xs:string*, $module as xs:string*) {
        try{
            $common:response-headers,
            datatypes:get-datatypes-shallow-list($schema, $version, $docLang, $module)
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

declare %private function datatypes:get-datatypes-shallow-list(
    $schema as xs:string, $version as xs:string,
    $docLangParam as xs:string*, $moduleParam as xs:string*) as map(*) {
        let $odd-source := common:odd-source($schema, $version)
        let $docLang := common:extract-query-parameters($docLangParam)
        let $module := common:extract-query-parameters($moduleParam)
        let $dataSpecs := $odd-source//tei:dataSpec => common:filter-by-module($module)
        return
            map {
                'data': array {
                    for $dataSpec in $dataSpecs
                    let $basic-data := common:get-spec-basic-data($dataSpec, $docLang)
                    let $dataSpecIdent := $dataSpec/data(@ident)
                    return
                        map {
                            'type': 'datatypes',
                            'id': common:encode-jsonapi-id($schema, $version, 'datatypes', $dataSpecIdent),
                            'attributes': $basic-data,
                            'links': map { 'self': common:build-absolute-uri(req:hostname#0, req:scheme#0, req:port#0, (rest:base-uri(), 'v2', $schema, $version, 'datatypes', $dataSpecIdent)) }
                        }
                } => array:sort((), function($obj) {$obj?attributes?ident}),
                'links': map { 'self': common:build-absolute-uri(req:hostname#0, req:scheme#0, req:port#0, rest:uri()) }
            }
};
