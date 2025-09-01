xquery version "3.1";

module namespace it="http://odd-api.edirom.de/xql/integration-tests";

declare namespace hc ="http://expath.org/ns/http-client";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace util="http://exist-db.org/xquery/util";

declare variable $it:base-url := "http://localhost:8080/restxq";

declare
    %test:args('/v2/mei/5.0')    %test:assertEquals("data", "links")
    %test:args('/v2/tei/3.6.0')    %test:assertEquals("data", "links")
    %test:args('/v2/tei/3.6.0/elements')    %test:assertEquals("data", "links")
    %test:args('/v2/tei/4.9.0/modules')    %test:assertEquals("data", "links")
    %test:args('/v2/mei/4.0.1/classes')    %test:assertEquals("data", "links")
    %test:args('/v2/tei/3.6.0/elements/span')    %test:assertEquals("data", "links")
    %test:args('/v2/tei/3.6.x')    %test:assertEquals("errors")
    %test:args('/v2/tei/3.6.x/elements')    %test:assertEquals("errors")
    %test:args('/v2/tei/3.6.x/elements/span')    %test:assertEquals("errors")
    %test:args('/v2/tei/3.6.0/elementsx')    %test:assertEquals("errors")
    function it:json-api-top-level-structure($endpoint as xs:string) as xs:string* {
        let $req :=
            <hc:request method="GET" href="{$it:base-url || $endpoint}">
                <hc:header name="Accept" value="application/vnd.api+json"/>
            </hc:request>
        return
            hc:send-request($req)[2] => util:base64-decode()
            => parse-json() => map:keys()
};

declare
    %test:args('/v2/mei/5.0')    %test:assertTrue
    %test:args('/v2/tei/3.6.0')    %test:assertTrue
    %test:args('/v2/tei/3.6.0/elements')    %test:assertTrue
    %test:args('/v2/tei/4.9.0/modules')    %test:assertTrue
    %test:args('/v2/mei/4.0.1/classes')    %test:assertTrue
    %test:args('/v2/tei/3.6.0/elements/span')    %test:assertTrue
    %test:args('/v2/tei/3.6.x')    %test:assertFalse
    %test:args('/v2/tei/3.6.x/elements')    %test:assertFalse
    %test:args('/v2/tei/3.6.x/elements/span')    %test:assertFalse
    %test:args('/v2/tei/3.6.0/elementsx')    %test:assertFalse
    function it:json-api-data-structure($endpoint as xs:string) as xs:boolean {
        let $req :=
            <hc:request method="GET" href="{$it:base-url || $endpoint}">
                <hc:header name="Accept" value="application/vnd.api+json"/>
            </hc:request>
        return
            (
                hc:send-request($req)[2] => util:base64-decode()
                => parse-json() => map:get('data')
            )
            instance of array(*)
};

declare
    %test:args('/v2/mei/5.0')    %test:assertEquals("1")
    %test:args('/v2/tei/3.6.0')    %test:assertEquals("1")
    %test:args('/v2/tei/3.6.0/elements')    %test:assertEquals("576")
    %test:args('/v2/tei/4.9.0/modules')    %test:assertEquals("22")
    %test:args('/v2/mei/4.0.1/classes')    %test:assertEquals("826")
    %test:args('/v2/tei/3.6.0/elements/span')    %test:assertEquals("1")
    function it:json-api-data-array-size($endpoint as xs:string) as xs:int {
        let $req :=
            <hc:request method="GET" href="{$it:base-url || $endpoint}">
                <hc:header name="Accept" value="application/vnd.api+json"/>
            </hc:request>
        return
            hc:send-request($req)[2] => util:base64-decode()
            => parse-json() => map:get('data')
            => array:size()
};
