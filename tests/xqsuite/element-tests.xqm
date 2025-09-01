xquery version "3.1";

module namespace et="http://odd-api.edirom.de/xql/element-tests";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace test="http://exist-db.org/xquery/xqsuite";

import module namespace elements="http://odd-api.edirom.de/xql/elements" at "/db/apps/odd-api/resources/xql/elements.xqm";
import module namespace common="http://odd-api.edirom.de/xql/common" at "/db/apps/odd-api/resources/xql/common.xqm";

declare
    %test:args('tei', '4.10.1', 'ab')    %test:assertEquals("ana cert change copyOf corresp decls exclude facs generatedBy hand n next part prev rend rendition resp sameAs select source style subtype synch type xml:base xml:id xml:lang xml:space")
    %test:args('tei', '3.6.0', 'ab')    %test:assertEquals("ana cert change copyOf corresp decls exclude facs hand n next part prev rend rendition resp sameAs select source style subtype synch type xml:base xml:id xml:lang xml:space")
    function et:test-attribute-list(
        $schema as xs:string, $version as xs:string,
        $elementIdent as xs:string) as xs:string {
            let $odd-source := common:odd-source($schema, $version)
            let $spec := $odd-source//tei:elementSpec[@ident = $elementIdent]
            return
                elements:work-out-attributes($spec, $odd-source, 'en')?ident => sort() => string-join(' ')
};

declare
    %test:args('tei', '4.10.1', 'ab')    %test:assertEquals("ab abbr add addName addSpan address affiliation alt altGrp am anchor app att bibl biblFull biblStruct binaryObject bloc c caesura camera caption castList catchwords cb certainty choice cit cl classSpec climate code constraintSpec corr country damage damageSpan dataSpec date del delSpan depth desc dim dimensions distinct district eg egXML elementSpec ellipsis email emph eventName ex expan fLib figure floatingText foreign forename formula fs fvLib fw g gap gb genName geo geogFeat geogName gi gloss graphic handShift height heraldry hi ident idno incident index interp interpGrp join joinGrp kinesic l label lang lb lg link linkGrp list listApp listBibl listEvent listNym listObject listOrg listPerson listPlace listRef listRelation listTranspose listWit location locus locusGrp m macroSpec material measure measureGrp media mentioned metamark milestone mod moduleSpec move msDesc name nameLink notatedMusic note noteGrp num oRef objectName objectType offset orgName orig origDate origPlace outputRendition pRef pause pb pc persName persPronouns phr placeName population precision ptr q quote redo ref reg region respons restore retrace rhyme roleName rs ruby s said secFol secl seg settlement shift sic signatures soCalled sound space span spanGrp specDesc specGrp specGrpRef specList stage stamp state subst substJoin supplied surname surplus table tag tech term terrain time timeline title trait unclear undo unit val view vocal w watermark width witDetail writing")
    %test:args('tei', '3.6.0', 'ab')    %test:assertEquals("abbr add addName addSpan address affiliation alt altGrp am anchor app att bibl biblFull biblStruct binaryObject bloc c caesura camera caption castList catchwords cb certainty choice cit cl classSpec climate code constraintSpec corr country damage damageSpan dataSpec date del delSpan depth desc dim dimensions distinct district eg egXML elementSpec email emph ex expan fLib figure floatingText foreign forename formula fs fvLib fw g gap gb genName geo geogFeat geogName gi gloss graphic handShift height heraldry hi ident idno incident index interp interpGrp join joinGrp kinesic l label lang lb lg link linkGrp list listApp listBibl listEvent listNym listObject listOrg listPerson listPlace listRef listRelation listTranspose listWit location locus locusGrp m macroSpec material measure measureGrp media mentioned metamark milestone mod moduleSpec move msDesc name nameLink notatedMusic note num oRef objectName objectType offset orgName orig origDate origPlace outputRendition pRef pause pb pc persName phr placeName population precision ptr q quote redo ref reg region respons restore retrace rhyme roleName rs s said secFol secl seg settlement shift sic signatures soCalled sound space span spanGrp specDesc specGrp specGrpRef specList stage stamp state subst substJoin supplied surname surplus table tag tech term terrain time timeline title trait unclear undo unit val view vocal w watermark width witDetail writing")
    %test:args('mei', '5.1', 'beam')    %test:assertEquals("add app bTrem barLine beam beatRpt choice chord clef clefGrp corr custos damage del fTrem gap graceGrp halfmRpt handShift keySig meterSig meterSigGrp note orig pad reg rest restore sic space subst supplied tabGrp tuplet unclear")
    function et:test-element-content(
        $schema as xs:string, $version as xs:string,
        $elementIdent as xs:string) as xs:string {
            let $odd-source := common:odd-source($schema, $version)
            let $spec := $odd-source//tei:elementSpec[@ident = $elementIdent]
            return
                 elements:work-out-content($spec, $odd-source)?* => string-join(' ')
};
