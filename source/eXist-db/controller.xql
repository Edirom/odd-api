xquery version "3.0";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

(: get all available modules :)
if(matches($exist:path,'/[a-z]+/[\da-zA-Z-_\.]+/modules.json$')) then (
    
    response:set-header("Access-Control-Allow-Origin", "*"),
    
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/getModules.xql">
            <add-parameter name="format" value="{tokenize($exist:path,'/')[last() - 2]}"/>
            <add-parameter name="version" value="{tokenize($exist:path,'/')[last() - 1]}"/>
        </forward>
    </dispatch>

(: gets the elements of a given module :)
) else if(matches($exist:path,'/[a-z]+/[\da-zA-Z-_\.]+/[\da-zA-Z-_\.]+/elements.json$')) then (
    
    response:set-header("Access-Control-Allow-Origin", "*"),
    
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/getElementsByModule.xql">
            <add-parameter name="format" value="{tokenize($exist:path,'/')[last() - 3]}"/>
            <add-parameter name="version" value="{tokenize($exist:path,'/')[last() - 2]}"/>
            <add-parameter name="module" value="{tokenize($exist:path,'/')[last() - 1]}"/>
        </forward>
    </dispatch>
    
(: gets the attribute classes of a given module :)
) else if(matches($exist:path,'/[a-z]+/[\da-zA-Z-_\.]+/[\da-zA-Z-_\.]+/attClasses.json$')) then (
    
    response:set-header("Access-Control-Allow-Origin", "*"),
    
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/getAttClassesByModule.xql">
            <add-parameter name="format" value="{tokenize($exist:path,'/')[last() - 3]}"/>
            <add-parameter name="version" value="{tokenize($exist:path,'/')[last() - 2]}"/>
            <add-parameter name="module" value="{tokenize($exist:path,'/')[last() - 1]}"/>
        </forward>
    </dispatch>
    
(: gets the attributes of a given element :)
) else if(matches($exist:path,'/[a-z]+/[\da-zA-Z-_\.]+/[\da-zA-Z-_\.]+/atts.json$')) then (
    
    response:set-header("Access-Control-Allow-Origin", "*"),
    
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/getAttsByElement.xql">
            <add-parameter name="format" value="{tokenize($exist:path,'/')[last() - 3]}"/>
            <add-parameter name="version" value="{tokenize($exist:path,'/')[last() - 2]}"/>
            <add-parameter name="element" value="{tokenize($exist:path,'/')[last() - 1]}"/>
        </forward>
    </dispatch>

) else if ($exist:path eq '') then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="index.html"/>
    </dispatch>
)    
else if ($exist:path eq "/") then (
    (: forward root path to index.xql :)
    response:set-header("Access-Control-Allow-Origin", "*"),
    
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="index.html"/>
    </dispatch>
)
else (
    (: everything else is passed through :)
    
    response:set-header("Access-Control-Allow-Origin", "*"),
    
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </dispatch>
)
