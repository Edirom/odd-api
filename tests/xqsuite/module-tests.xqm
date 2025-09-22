xquery version "3.1";

module namespace mt="http://odd-api.edirom.de/xql/module-tests";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace test="http://exist-db.org/xquery/xqsuite";

import module namespace modules="http://odd-api.edirom.de/xql/modules" at "/db/apps/odd-api/resources/xql/modules.xqm";
import module namespace common="http://odd-api.edirom.de/xql/common" at "/db/apps/odd-api/resources/xql/common.xqm";

declare
    %test:args('tei', '4.10.1', 'analysis') %test:assertEquals("c cl interp interpGrp m pc phr s span spanGrp w")
    %test:args('tei', '3.6.0', 'header')    %test:assertEquals("abstract appInfo application authority availability biblFull cRefPattern calendar calendarDesc catDesc catRef category change classCode classDecl conversion correction correspAction correspContext correspDesc creation distributor edition editionStmt editorialDecl encodingDesc extent fileDesc funder geoDecl handNote hyphenation idno interpretation keywords langUsage language licence listChange listPrefixDef namespace normalization notesStmt prefixDef principal profileDesc projectDesc publicationStmt punctuation quotation refState refsDecl rendition revisionDesc samplingDecl schemaRef scriptNote segmentation seriesStmt sourceDesc sponsor stdVals styleDefDecl tagUsage tagsDecl taxonomy teiHeader textClass titleStmt unitDecl unitDef xenoData")
    function mt:test-element-members-list(
        $schema as xs:string, $version as xs:string,
        $moduleIdent as xs:string) as xs:string* {
            let $odd-source := common:odd-source($schema, $version)
            return
                modules:work-out-members($odd-source, $moduleIdent, ())?*[?type='element']?ident => string-join(' ')
};
