xquery version "3.1";

declare namespace util="http://exist-db.org/xquery/util";

(: the following line must be added to each of the modules that include unit tests :)
import module namespace test="http://exist-db.org/xquery/xqsuite" at "resource:org/exist/xquery/lib/xqsuite/xqsuite.xql";
 
import module namespace it="http://odd-api.edirom.de/xql/integration-tests" at "integration-tests.xqm";
import module namespace et="http://odd-api.edirom.de/xql/element-tests" at "element-tests.xqm";
import module namespace mt="http://odd-api.edirom.de/xql/module-tests" at "module-tests.xqm";

(: the test:suite() function will run all the test-annotated functions in the module whose namespace URI you provide :)
test:suite((
    util:list-functions("http://odd-api.edirom.de/xql/integration-tests"),
    util:list-functions("http://odd-api.edirom.de/xql/element-tests"),
    util:list-functions("http://odd-api.edirom.de/xql/module-tests")
))
