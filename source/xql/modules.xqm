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
    %rest:query-param("docLang", "{$docLang}", "")
    %output:media-type("application/vnd.api+json")
    %output:method("json")
    function modules:get-modules($schema as xs:string, $version as xs:string, $docLang as xs:string*) {
        try{
            $common:response-headers,
            modules:get-modules-shallow-list($schema, $version, $docLang)
        }
        catch * {
            common:set-status($common:response-headers, 404),
            common:json-api-error-object(
                $err:description,
                common:build-absolute-uri(req:hostname#0, req:scheme#0, req:port#0, rest:uri()),
                404,
                string($err:code)
            )
        }
};

declare
    %rest:GET
    %rest:path("/v2/{$schema}/{$version}/modules/{$id}")
    %rest:query-param("docLang", "{$docLang}", "")
    %output:media-type("application/vnd.api+json")
    %output:method("json")
    function modules:get-module(
        $schema as xs:string, $version as xs:string,
        $id as xs:string, $docLang as xs:string*
        ) {
            try {
                $common:response-headers,
                modules:get-module-details($schema, $version, $id, $docLang)
            }
            catch * {
                common:set-status($common:response-headers, 404),
                common:json-api-error-object(
                    $err:description,
                    common:build-absolute-uri(req:hostname#0, req:scheme#0, req:port#0, rest:uri()),
                    404,
                    string($err:code)
                )
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

declare %private function modules:get-modules-shallow-list(
    $schema as xs:string, $version as xs:string,
    $docLangParam as xs:string*) as map(*) {
        let $odd-source := common:odd-source($schema, $version)
        let $docLang := common:extract-query-parameters($docLangParam)
        let $modules :=
            for $module in $odd-source//tei:moduleSpec
            let $spec-basic-data := common:get-spec-basic-data($module, $docLang)
(:            let $elementCount := count($odd-source//tei:elementSpec[@module = $spec-basic-data?ident]):)
(:            let $attClassCount := count($odd-source//tei:classSpec[@type = 'atts'][@module = $spec-basic-data?ident]):)
            let $id := common:encode-jsonapi-id($schema, $version, 'modules', $spec-basic-data?ident)
            return
                map {
                    'type': 'modules',
                    'id': $id,
                    'attributes': $spec-basic-data,
                    "links": map {
                        "self": common:build-absolute-uri(req:hostname#0, req:scheme#0, req:port#0, rest:uri() || '/' || $spec-basic-data?ident)
                    }
                }
        return
            map {
                'data': array { $modules } => array:sort((), function($module) {$module?attributes?ident}),
                'links': map {
                    'self': common:build-absolute-uri(req:hostname#0, req:scheme#0, req:port#0, rest:uri())
                }
            }
};

declare function modules:get-module-details(
    $schema as xs:string,
    $version as xs:string,
    $id as xs:string,
    $docLang as xs:string*) as map(*) {
        let $odd-source := common:odd-source($schema, $version)
        let $decoded-id := common:decode-jsonapi-id($id)?ident
        let $moduleIdent :=
            if($decoded-id) then $decoded-id
            else $id
        let $moduleSpec := $odd-source//tei:moduleSpec[@ident = $moduleIdent]
        return
            if($moduleSpec)
            then
                let $basic-data := common:get-spec-basic-data($moduleSpec, $docLang)
                let $members := modules:work-out-members($odd-source, $moduleIdent, $docLang)
                return
                    map {
                        'data': array {
                            map {
                                'type': 'moduleDetails',
                                'id': common:encode-jsonapi-id($schema, $version, 'modules', $moduleIdent),
                                'attributes': map:put($basic-data, 'members', $members),
                                'links': map { 'self': common:build-absolute-uri(req:hostname#0, req:scheme#0, req:port#0, (rest:base-uri(), 'v2', $schema, $version, 'modules', $moduleIdent)) }
                            }
                        },
                        'links': map { 'self': common:build-absolute-uri(req:hostname#0, req:scheme#0, req:port#0, rest:uri()) }
                    }
            else
                error(
                    $common:SPEC_NOT_FOUND_ERROR,
                    'No moduleSpec found for ident "' || $moduleIdent || '".'
                )
};

declare function modules:work-out-members(
    $odd-source as element(tei:TEI),
    $moduleIdent as xs:string,
    $docLang as xs:string*) as array(*) {
        array {(
            $odd-source//tei:elementSpec[@module = $moduleIdent] |
            $odd-source//tei:classSpec[@module = $moduleIdent] |
            $odd-source//tei:dataSpec[@module = $moduleIdent] |
            $odd-source//tei:macroSpec[@module = $moduleIdent]
            ) ! common:get-spec-basic-data(., $docLang)
        } => array:sort((), function($obj) {$obj?ident})
};
