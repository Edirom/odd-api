xquery version "3.1";

module namespace index="http://odd-api.edirom.de/xql/index";

declare namespace http="http://expath.org/ns/http-client";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace req="http://exquery.org/ns/request";
declare namespace rest="http://exquery.org/ns/restxq";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";

import module namespace common="http://odd-api.edirom.de/xql/common" at "common.xqm";
import module namespace config="http://odd-api.edirom.de/xql/config" at "config.xqm";

(:~
 : index.html file
 :)
declare
    %rest:GET
    %rest:path("/index.html")
    %rest:produces("text/html")
    %output:media-type("text/html")
    %output:method("html")
    function index:index-html-redirect() as document-node(element(rest:response)) {
        index:redirect-to-default-index-html()
};

(:~
 : v1 redirect
 :)
declare
    %rest:GET
    %rest:path("/v1")
    %rest:produces("text/html")
    %output:media-type("text/html")
    %output:method("html")
    function index:index-html-v1-redirect() as document-node(element(rest:response)) {
        index:redirect-to-default-index-html()
};

(:~
 : index.html file v1
 :)
declare
    %rest:GET
    %rest:path("/v1/index.html")
    %rest:produces("text/html")
    %output:media-type("text/html")
    %output:method("html")
    function index:index-html-v1() {
        $common:response-headers,
        doc($config:app-root || '/index.html')
};

(:~
 : v2 redirect
 :)
declare
    %rest:GET
    %rest:path("/v2")
    %rest:produces("text/html")
    %output:media-type("text/html")
    %output:method("html")
    function index:index-html-v2-redirect() as document-node(element(rest:response)) {
        index:redirect('/v2/index.html')
};

(:~
 : index.html file v2
 :)
declare
    %rest:GET
    %rest:path("/v2/index.html")
    %rest:produces("text/html")
    %output:media-type("text/html")
    %output:method("html")
    function index:index-html-v2() {
        $common:response-headers,
        doc($config:app-root || '/index.html')
};

(:~
 : OpenAPI definition file v1
 :)
declare
    %rest:GET
    %rest:path("/v1/openapi.yaml")
    %rest:produces("application/yaml")
    %output:media-type("application/yaml")
    %output:method("text")
    function index:swagger-ui-v1() {
        $common:response-headers,
        unparsed-text($config:app-root || '/openapi_v1.yaml')
};

(:~
 : OpenAPI definition file v2
 :)
declare
    %rest:GET
    %rest:path("/v2/openapi.yaml")
    %rest:produces("application/yaml")
    %output:media-type("application/yaml")
    %output:method("text")
    function index:swagger-ui-v2() {
        $common:response-headers,
        unparsed-text($config:app-root || '/openapi_v2.yaml')
};

(:~
 : Schemas endpoint for GET requests
 : Shallow schema information is provided for each available schema label, e.g. "tei_all", or "mei_cmm"
 :)
declare
    %rest:GET
    %rest:path("/v2/schemas")
    %rest:produces("application/vnd.api+json")
    %output:media-type("application/vnd.api+json")
    %output:method("json")
    function index:list-schemas-v2() {
        $common:response-headers,
        map {
            'data': array {
                for $schema in xmldb:get-child-collections($config:data-root)
                order by $schema
                return
                    map {
                        'type': 'schemas',
                        'id': 'schema_' || $schema,
                        'attributes': map {
                            'ident': $schema,
                            'versions':
                                array {
                                    xmldb:get-child-collections($config:data-root || '/' || $schema) => sort()
                                }
                        },
                        'links': map {
                            'self': common:build-absolute-uri(req:hostname#0, req:scheme#0, req:port#0, (rest:base-uri(), 'v2', $schema))
                        }
                    }
                },
                'links': map {
                    'self': common:build-absolute-uri(req:hostname#0, req:scheme#0, req:port#0, rest:uri())
                }
            }
};

(:~
 : Schemas endpoint for POST requests
 :)
declare
    %rest:POST("{$request-body}")
    %rest:path("/v2/schemas")
    %rest:consumes("application/xml")
    %rest:produces("application/vnd.api+json")
    %output:media-type("application/vnd.api+json")
    %output:method("json")
    function index:post-schema-v2($request-body as document-node()) {
        let $odd-source := $request-body/tei:TEI
        return
            if($odd-source)
            then (
                $common:response-headers,
                map {
                    'data':
                        array {
                            map {
                                'type': 'schemaDetails',
                                'id': 'user-upload',
                                'attributes': map:merge((
                                    map {
                                        'ident': 'user-upload',
                                        'version': util:hash($odd-source, 'md5')
                                    },
                                    index:schema-details($odd-source)
                                ))
                            }
                        },
                        'links': map {
                            'self': common:build-absolute-uri(req:hostname#0, req:scheme#0, req:port#0, rest:uri())
                        }
                    }
            )
            else (
                common:set-status($common:response-headers, 404),
                common:error-not-found('some error occured', common:build-absolute-uri(req:hostname#0, req:scheme#0, req:port#0, rest:uri()))
            )
};

(:~
 : Endpoint for a specific schema, e.g. "tei_all", or "mei_cmm"
 : A shallow list of available versions of this schemas will be returned
 :)
declare
    %rest:GET
    %rest:path("/v2/{$schema}")
    %rest:produces("application/vnd.api+json")
    %output:media-type("application/vnd.api+json")
    %output:method("json")
    function index:list-schema-versions-v2($schema as xs:string) {
        if(xmldb:collection-available($config:data-root || '/' || $schema))
        then (
            $common:response-headers,
            map {
                'data': array {
                    for $version in xmldb:get-child-collections($config:data-root || '/' || $schema)
                    order by $version
                    return
                    map {
                        'type': 'schemas',
                        'id': 'schema_' || $schema || '_' || $version,
                        'attributes': map {
                            'ident': $schema,
                            'versions':
                                array {
                                    $version
                                }
                        },
                        'links': map {
                            'self': common:build-absolute-uri(req:hostname#0, req:scheme#0, req:port#0, (rest:base-uri(), 'v2', $schema, $version))
                        }
                    }
                },
                'links': map {
                    'self': common:build-absolute-uri(req:hostname#0, req:scheme#0, req:port#0, rest:uri())
                }
            }
        )
        else (
            common:set-status($common:response-headers, 404),
            common:error-not-found('The requested schema "' || $schema || '" could not be found', common:build-absolute-uri(req:hostname#0, req:scheme#0, req:port#0, rest:uri()))
        )
};

(:~
 :  XML Endpoint for a specific schema version
 :  The raw ODD schema in TEI-XML format will be returned
 :)
declare
    %rest:GET
    %rest:path("/v2/{$schema}/{$version}")
    %rest:produces("application/xml")
    %output:media-type("application/xml")
    %output:method("xml")
    function index:get-odd-source-v2($schema as xs:string, $version as xs:string) {
        let $odd-source := common:odd-source($schema, $version)
        return
            if($odd-source)
            then (
                $common:response-headers,
                $odd-source
            )
            else (
                common:set-status($common:response-headers, 404),
                <error code="404">{'The requested version "' || $version || '" for schema "' || $schema || '" could not be found'}</error>
            )
};

(:~
 :  JSON Endpoint for a specific schema version
 :  A JSON representation of the schema details, i.e. a "fingerprint" of the schema will be returned
 :)
declare
    %rest:GET
    %rest:path("/v2/{$schema}/{$version}")
    %rest:produces("application/vnd.api+json")
    %output:media-type("application/vnd.api+json")
    %output:method("json")
    function index:get-schema-details-v2($schema as xs:string, $version as xs:string) {
        let $odd-source := common:odd-source($schema, $version)
        return
            if($odd-source)
            then (
                $common:response-headers,
                map {
                    'data':
                        array {
                            map {
                                'type': 'schemaDetails',
                                'id': 'schema_' || $schema || '_' || $version,
                                'attributes': map:merge((
                                    map {
                                        'ident': $schema,
                                        'version': $version
                                    },
                                    index:schema-details($odd-source)
                                )),
                                'links': map {
                                    'self': common:build-absolute-uri(req:hostname#0, req:scheme#0, req:port#0, (rest:base-uri(), 'v2', $schema, $version))
                                }
                            }
                        },
                        'links': map {
                            'self': common:build-absolute-uri(req:hostname#0, req:scheme#0, req:port#0, rest:uri())
                        }
                    }
            )
            else (
                common:set-status($common:response-headers, 404),
                common:error-not-found('The requested version "' || $version || '" for schema "' || $schema || '" could not be found', common:build-absolute-uri(req:hostname#0, req:scheme#0, req:port#0, rest:uri()))
            )
};


declare %private function index:redirect-to-default-index-html() as document-node(element(rest:response)) {
    index:redirect('/v1/index.html')
};

declare %private function index:redirect($path as xs:string) as document-node(element(rest:response)) {
    document {
        <rest:response>
          <http:response status="302" message="Temporary Redirect">
            <http:header name="location" value="{rest:base-uri()}/{replace($path, '^/', '')}"/>
            <http:header name="Access-Control-Allow-Origin" value="*"/>
          </http:response>
        </rest:response>
    }
};

declare %private function index:schema-details($odd-source as element(tei:TEI)) as map(*) {
    map {
        'releaseDate': $odd-source/tei:teiHeader/tei:fileDesc/tei:editionStmt/tei:edition/tei:date[1]/data(@when),
        'title': $odd-source/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[1] => normalize-space(),
        'defaultNamespace': common:work-out-namespace($odd-source//tei:schemaSpec[1]),
        'elements': array { $odd-source//tei:elementSpec/data(@ident) => sort() },
        'attributes': array { $odd-source//tei:attDef/@ident => distinct-values() => sort() },
        'teiDistance': '',
        'meiDistance': ''
    }
};
