xquery version "3.1";

(:~
 : Common module for the ODD API with shared utility functions
 :)
module namespace common="http://odd-api.edirom.de/xql/common";

declare namespace http="http://expath.org/ns/http-client";
declare namespace rest="http://exquery.org/ns/restxq";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";

import module namespace config="http://odd-api.edirom.de/xql/config" at "config.xqm";

declare variable $common:ODD_NOT_FOUND_ERROR := QName("http://odd-api.edirom.de/xql/common", "OddNotFoundError");
declare variable $common:SPEC_NOT_FOUND_ERROR := QName("http://odd-api.edirom.de/xql/common", "SpecNotFoundError");

(:~
 : Standard response headers for all API responses, including CORS configuration
 :)
declare variable $common:response-headers :=
    <rest:response>
        <http:response>
            <http:header name="Access-Control-Allow-Origin" value="*"/>
        </http:response>
    </rest:response>;

(:~
 : Sets a response header with total record count
 : @param $response-headers The existing response headers
 : @param $totalrecordcount The total number of records
 : @return Updated response headers with total record count
 :)
declare function common:set-response-header-totalrecordcount($response-headers as element(rest:response), $totalrecordcount as xs:nonNegativeInteger) as element(rest:response) {
    element {$response-headers/name()} {
        $response-headers/@*,
        element {$response-headers/http:response/name()} {
            $response-headers/http:response/* except $response-headers/http:response/http:header[@name = 'totalrecordcount'],
            <http:header name="totalrecordcount" value="{$totalrecordcount}"/>
        }
    }
};

(:~
 : Sets the HTTP status code in response headers
 : @param $response-headers The existing response headers
 : @param $status The HTTP status code to set
 : @return Updated response headers with new status
 :)
declare function common:set-status($response-headers as element(rest:response), $status as xs:integer) as element(rest:response) {
    element {$response-headers/name()} {
        $response-headers/@*,
        element {$response-headers/http:response/name()} {
            $response-headers/http:response/@* except $response-headers/http:response/@status,
            attribute status {
                $status
            },
            $response-headers/http:response/*
        }
    }
};

(:~
 : Calculates a limit value for pagination
 : @param $limit The requested limit
 : @return A positive integer limit value, bounded by config:max-limit
 :)
declare function common:get-limit($limit as xs:string*) as xs:positiveInteger {
    if($limit[1] castable as xs:positiveInteger)
    then min(($config:max-limit, xs:positiveInteger($limit[1]))) cast as xs:positiveInteger
    else $config:max-limit
};

(:~
 : Calculates an offset value for pagination
 : @param $offset The requested offset
 : @return A positive integer offset value, defaulting to 1
 :)
declare function common:get-offset($offset as xs:string*) as xs:positiveInteger {
    if($offset[1] castable as xs:positiveInteger)
    then xs:positiveInteger($offset[1])
    else 1
};

(:~
 : Extracts description and gloss from a specification element
 : @param $spec The TEI element containing desc and gloss elements
 : @param $docLang Language code for documentation (e.g., "en")
 : @return A map with 'ident', 'desc', 'gloss', 'type', 'namespace', and 'module' entries
 :)
declare function common:get-spec-basic-data($spec as element(), $docLang as xs:string*) as map(*) {
    let $module := $spec/data(@module)
    let $type :=
        if($spec/@type = 'atts') then 'attributeClass'
        else if($spec/@type = 'model') then 'modelClass'
        else fn:substring-before($spec/fn:local-name(), 'Spec')
    let $namespace := common:work-out-namespace($spec)
    let $spec-basic-data :=
        map {
            'ident': $spec/data(@ident),
            'desc':
                array {
                    if($docLang)
                    then $spec/tei:desc[@xml:lang = $docLang] ! map { "lang": string(./@xml:lang), "text": normalize-space(.) }
                    else $spec/tei:desc ! map { "lang": string(./@xml:lang), "text": normalize-space(.) }
                } => array:sort((), function($obj) {$obj?lang})
        }
    return
        switch($type)
        case 'element' return
            map:merge(($spec-basic-data, map {
                'gloss':
                    array {
                        if($docLang)
                        then $spec/tei:gloss[@xml:lang = $docLang] ! map { "lang": string(./@xml:lang), "text": normalize-space(.) }
                        else $spec/tei:gloss ! map { "lang": string(./@xml:lang), "text": normalize-space(.) }
                    } => array:sort((), function($obj) {$obj?lang}),
                'module': $module,
                'namespace': $namespace
            }))
        case 'attributeClass' case 'modelClass' return
            map:merge(($spec-basic-data, map {
                'module': $module
            }))
        default return $spec-basic-data
};

(:~
 : Retrieves the ODD source document based on schema and version
 : @param $schema The schema identifier (e.g., "tei" or "mei")
 : @param $version The schema version (e.g., "5.0")
 : @return The TEI document containing the ODD specification
 :)
declare function common:odd-source($schema as xs:string, $version as xs:string) as element(tei:TEI)? {
    if(xmldb:collection-available(string-join(($config:data-root, $schema, $version), '/')))
    then
        collection(string-join(($config:data-root, $schema, $version), '/'))//tei:TEI[1]
    else error($common:ODD_NOT_FOUND_ERROR, 'ODD source not available for the provided combination of schema="' || $schema || '" and version="' || $version || '".')
};

(:~
 : Determines the namespace for a specification element
 : @param $spec The TEI specification element
 : @return The namespace URI as string, or default TEI namespace if not specified
 :)
declare function common:work-out-namespace($spec as element()?) as xs:string {
    if($spec/@ns)
    then $spec/data(@ns)
    else
        if($spec/ancestor::tei:schemaSpec/@ns)
        then $spec/ancestor::tei:schemaSpec/data(@ns)
        else 'http://www.tei-c.org/ns/1.0'
};

declare function common:build-absolute-uri($hostname as function(*), $scheme as function(*), $port as function(*), $path-segments as xs:anyAtomicType+) as xs:string? {
    let $host := $hostname()
    let $scheme := $scheme()
    let $port := $port()
    let $path := string-join($path-segments, '/') => replace('/+', '/') => replace('^/','')
    return
        if($port = 80 or $port = 443)
        then concat($scheme, '://', $host, '/', $path)
        else concat($scheme, '://', $host, ':', $port, '/', $path)
};

declare function common:get-direct-attributes-v1(
    $spec as element(),
    $docLang as xs:string
    ) as array(*) {
        let $atts :=
            for $attDef in $spec//tei:attDef
            let $spec-basic-data := common:get-spec-basic-data($attDef, $docLang)
            return
                map {
                    'name': $spec-basic-data?ident,
                    'desc': $spec-basic-data?desc
                }
        return
            array { $atts } => array:sort((), function($att) {$att?name})
};

(:~
 : Generates a JSON API identifier based on schema, version, resource type and identifier
 :
 : @param $schema The schema identifier (e.g., "tei", "mei")
 : @param $version The schema version (e.g., "5.0")
 : @param $resource The type of the resource (e.g., "element", "module")
 : @param $ident The identifier of the resource
 : @return A string representing the JSON API identifier
 :)
declare function common:encode-jsonapi-id(
    $schema as xs:string,
    $version as xs:string?,
    $resource as xs:string?,
    $ident as xs:string?) as xs:string {
        string-join(($schema, $version, $resource, $ident), '&#xE000;')
        => util:base64-encode()
};

(:~
 : Decodes a JSON API identifier into its components: schema, version, resource type, and identifier
 :
 : @param $id The JSON API identifier string
 : @return A map with keys 'schema', 'version', 'resource', and 'ident'
 :)
declare function common:decode-jsonapi-id($id as xs:string) as map(*) {
    let $parts := $id => util:base64-decode() => tokenize('&#xE000;')
    return
        map {
            'schema': $parts[1],
            'version': if(count($parts) >= 2) then $parts[2] else (),
            'resource': if(count($parts) >= 3) then $parts[3] else (),
            'ident': if(count($parts) >= 4) then $parts[4] else ()
        }
};

declare function common:json-api-error-object(
    $title as xs:string, $source as xs:string,
    $status as xs:integer?, $code as xs:string?) as map(*) {
        map {
            'errors':
                array {
                    map {
                        'code': if($code) then string($code) else 'unknownError',
                        'detail': 'The OpenAPI documentation of the ODD-API can be found at https://odd-api.edirom.de/v2/index.html. If you find the specification or implementation faulty please file an issue at https://github.com/Edirom/odd-api/issues.',
                        'source': $source,
                        'status': if($status) then string($status) else '404',
                        'title': $title
                    }
                }
        }
};

declare function common:extract-query-parameters($param as xs:string*) as xs:string* {
    ($param ! xmldb:decode-uri(.) ! tokenize(., ',') ! normalize-space(.))[.]
};

declare function common:filter-by-module($specs as element()*, $modules as xs:string*) as element()* {
    if($modules) then $specs[@module=$modules] | $specs[ancestor::tei:elementSpec/@module=$modules]
    else $specs
};

declare function common:filter-by-class($specs as element()*, $classes as xs:string*) as element()* {
    if($classes) then $specs[tei:classes/tei:memberOf[not(@mode='delete')]/@key=$classes] | $specs[ancestor::tei:classSpec[not(@mode='delete')]/@ident=$classes]
    else $specs
};
