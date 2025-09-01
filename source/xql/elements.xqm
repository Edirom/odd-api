xquery version "3.1";

module namespace elements="http://odd-api.edirom.de/xql/elements";

declare namespace array="http://www.w3.org/2005/xpath-functions/array";
declare namespace err="http://www.w3.org/2005/xqt-errors";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace range="http://exist-db.org/xquery/range";
declare namespace rest="http://exquery.org/ns/restxq";
declare namespace req="http://exquery.org/ns/request";
declare namespace rng="http://relaxng.org/ns/structure/1.0";
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

declare
    %rest:GET
    %rest:path("/v2/{$schema}/{$version}/elements")
    %rest:query-param("class", "{$class}", "")
    %rest:query-param("docLang", "{$docLang}", "")
    %rest:query-param("module", "{$module}", "")
    %rest:produces("application/vnd.api+json")
    %output:media-type("application/vnd.api+json")
    %output:method("json")
    function elements:get-elements(
        $schema as xs:string, $version as xs:string,
        $class as xs:string*, $docLang as xs:string*,
        $module as xs:string*
        ) {
            try{
                $common:response-headers,
                elements:get-elements-shallow-list($schema, $version, $class, $docLang, $module)
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

declare
    %rest:GET
    %rest:path("/v2/{$schema}/{$version}/elements/{$id}")
    %rest:query-param("docLang", "{$docLang}", "")
    %rest:produces("application/vnd.api+json")
    %output:media-type("application/vnd.api+json")
    %output:method("json")
    function elements:get-element(
        $schema as xs:string, $version as xs:string,
        $id as xs:string, $docLang as xs:string*
        ) {
            try {
                $common:response-headers,
                elements:get-element-details($schema, $version, $id, $docLang)
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

(:~
 : Retrieve all elements defined in a specific module
 : Helper function for elements:elements-v1
 :)
declare %private function elements:get-elements-v1(
    $schema as xs:string, $version as xs:string,
    $module as xs:string, $docLang as xs:string
    ) as array(*) {
        let $odd.source := common:odd-source($schema, $version)
        let $module.replaced := replace($module,'_','.')
        let $elements :=
            $odd.source//tei:elementSpec[@module = ($module, $module.replaced)] ! common:get-spec-basic-data-v1(., $docLang) ! map:remove(., 'module')
        return
            array { $elements } => array:sort((), function($elem) {$elem?name})
};

(:~
 : Retrieve all attributes defined directly for an element and
 : all attributes defined in attribute classes the element is member of, including
 : nested attribute classes.
 : Helper function for elements:element-attributes-v1
 :)
declare %private function elements:get-element-attributes-v1(
    $schema as xs:string, $version as xs:string,
    $element as xs:string, $docLang as xs:string
    ) as map(*) {
        let $odd.source := common:odd-source($schema, $version)
        let $elem := $odd.source//tei:elementSpec[@ident = $element]
        let $spec-basic-data := common:get-spec-basic-data-v1($elem, $docLang)
        let $direct-attributes := common:get-direct-attributes-v1($elem, $docLang)
        return
            map:merge((
                $spec-basic-data,
                map {
                    'atts': $direct-attributes,
                    'classes': classes:get-attribute-classes-recursively-v1($elem, $odd.source, $docLang)
                }
            ))
};

declare %private function elements:get-elements-shallow-list(
    $schema as xs:string, $version as xs:string,
    $classParam as xs:string*, $docLangParam as xs:string*,
    $moduleParam as xs:string*) as map(*)* {
        let $odd-source := common:odd-source($schema, $version)
        let $class := common:extract-query-parameters($classParam)
        let $docLang := common:extract-query-parameters($docLangParam)
        let $module := common:extract-query-parameters($moduleParam)
        let $elementSpecs := $odd-source//tei:elementSpec => common:filter-by-module($module) => common:filter-by-class($class)
        return
            map {
                'data': array {
                    for $elementSpec in $elementSpecs
                    let $basic-data := common:get-spec-basic-data($elementSpec, $docLang)
                    let $elementIdent := $elementSpec/data(@ident)
                    return
                        map {
                            'type': 'elements',
                            'id': common:encode-jsonapi-id($schema, $version, 'elements', $elementIdent),
                            'attributes': $basic-data,
                            'links': map { 'self': common:build-absolute-uri(req:hostname#0, req:scheme#0, req:port#0, (rest:base-uri(), 'v2', $schema, $version, 'elements', $elementIdent)) }
                        }
                } => array:sort((), function($obj) {$obj?attributes?ident}),
                'links': map { 'self': common:build-absolute-uri(req:hostname#0, req:scheme#0, req:port#0, rest:uri()) }
            }
};

declare %private function elements:get-element-details(
    $schema as xs:string,
    $version as xs:string,
    $id as xs:string,
    $docLang as xs:string*) as map(*) {
        let $odd-source := common:odd-source($schema, $version)
        let $decoded-id := common:decode-jsonapi-id($id)?ident
        let $elementIdent :=
            if($decoded-id) then $decoded-id
            else $id
        let $elementSpec := $odd-source//tei:elementSpec[@ident = $elementIdent]
        return
            if($elementSpec)
            then
                let $basic-data := common:get-spec-basic-data($elementSpec, $docLang)
                let $attributes :=
                    array { elements:work-out-attributes($elementSpec, $odd-source, $docLang) }
                    => array:sort((), function($att) {$att?ident})
                let $content := elements:work-out-content($elementSpec, $odd-source)
                return
                    map {
                        'data': array {
                            map {
                                'type': 'elementDetails',
                                'id': common:encode-jsonapi-id($schema, $version, 'elements', $elementIdent),
                                'attributes':
                                    map:put($basic-data, 'attributes', $attributes)
                                    => map:put('content', $content),
                                'links': map { 'self': common:build-absolute-uri(req:hostname#0, req:scheme#0, req:port#0, (rest:base-uri(), 'v2', $schema, $version, 'elements', $elementIdent)) }
                            }
                        },
                        'links': map { 'self': common:build-absolute-uri(req:hostname#0, req:scheme#0, req:port#0, rest:uri()) }
                    }
            else
                error(
                    $common:SPEC_NOT_FOUND_ERROR,
                    'No elementSpec found for ident "' || $elementIdent || '".'
                )
};

declare function elements:work-out-content($spec as element()?, $odd-source as element(tei:TEI)) as array(*) {
    array {(
        for $descendant in $spec/tei:content//*
        return
            typeswitch($descendant)
                case element(tei:classRef) return (
                    $odd-source//tei:elementSpec[tei:classes/tei:memberOf[not(@mode='delete')]/@key = $descendant/@key]/@ident,
                    $odd-source//tei:classSpec[tei:classes/tei:memberOf[not(@mode='delete')]/@key = $descendant/@key] ! elements:work-out-class-membership(., $odd-source)
                )
                case element(tei:elementRef) return $descendant/string(@key)
                case element(rng:ref) return
                    if($descendant/@name => starts-with('model.'))
                    then (
                        $odd-source//tei:elementSpec[tei:classes/tei:memberOf[not(@mode='delete')]/@key = $descendant/@name]/@ident,
                        $odd-source//tei:classSpec[tei:classes/tei:memberOf[not(@mode='delete')]/@key = $descendant/@name] ! elements:work-out-class-membership(., $odd-source)
                    )
                    else $descendant/string(@name)
                case element(tei:macroRef) return
                    $odd-source//tei:macroSpec[@ident = $descendant/@key] => elements:work-out-content($odd-source)
                case element(tei:empty) return 'empty'
                case element(tei:anyElement) return 'anyElement'
                default return ()
    ) => distinct-values()
    } => array:sort()
};

declare function elements:work-out-class-membership($spec as element()?, $odd-source as element(tei:TEI)) as xs:string* {
    $odd-source//tei:memberOf[range:eq(@key, $spec/@ident)]/ancestor::tei:elementSpec/string(@ident),
    $odd-source//tei:memberOf[range:eq(@key, $spec/@ident)]/ancestor::tei:classSpec ! elements:work-out-class-membership(., $odd-source)
};

(:~
 : Recursive retrieval of all attributes defined directly for an element and
 : all attributes defined in attribute classes the element is member of, including
 : nested attribute classes.
 : Local attributes are marked with 'class': 'local', attributes from attribute classes
 : are marked with their respective class ident.
 :
 : @param $odd-source The ODD source document
 : @param $spec The spec element (classSpec or elementSpec) for which to retrieve attributes
 : @return A sequence of maps
 :)
declare function elements:work-out-attributes(
    $spec as element()?, $odd-source as element(tei:TEI),
    $docLang as xs:string*) as map(*)* {
        $spec//tei:attDef ! common:get-spec-basic-data(., $docLang),
        for $key in $spec/tei:classes/tei:memberOf/@key[starts-with(.,'att.')]
        let $class := $odd-source//tei:classSpec[@type = 'atts'][@ident = $key]
        return elements:work-out-attributes($class, $odd-source, $docLang)
};
