xquery version "3.1";

module namespace index="http://odd-api.edirom.de/xql/index";

declare namespace http="http://expath.org/ns/http-client";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace req="http://exquery.org/ns/request";
declare namespace rest="http://exquery.org/ns/restxq";
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
                xmldb:get-child-collections($config:data-root)
                ! map {
                    'type': 'schemas',
                    'id': .,
                    'links': map {
                        'self': common:build-absolute-uri(req:hostname#0, req:scheme#0, req:port#0, (rest:base-uri(), 'v2', .))
                    }
                }
            },
            'links': map {
                'self': common:build-absolute-uri(req:hostname#0, req:scheme#0, req:port#0, rest:uri())
            }
        }
};

declare
    %rest:GET
    %rest:path("/v2/{$schema}")
    %rest:produces("application/vnd.api+json")
    %output:media-type("application/vnd.api+json")
    %output:method("json")
    function index:list-schema-versions-v2($schema as xs:string) {
        $common:response-headers,
        map {
            'data': array {
                xmldb:get-child-collections($config:data-root || '/' || $schema)
                ! map {
                    'type': 'versions',
                    'id': .,
                    'links': map {
                        'self': common:build-absolute-uri(req:hostname#0, req:scheme#0, req:port#0, (rest:base-uri(), 'v2', $schema, .))
                    }
                }
            },
            'links': map {
                'self': common:build-absolute-uri(req:hostname#0, req:scheme#0, req:port#0, rest:uri())
            }
        }
};

declare
    %rest:GET
    %rest:path("/v2/{$schema}/{$version}")
    %rest:produces("application/xml")
    %output:media-type("application/xml")
    %output:method("xml")
    function index:get-odd-source-v2($schema as xs:string, $version as xs:string) {
        $common:response-headers,
        common:odd-source($schema, $version)
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
