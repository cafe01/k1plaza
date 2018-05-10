
var $ = require('k1/jquery')

test.is( $("<div/>").attr("class", "foo").as_html(), '<div class="foo"></div>', "div.foo" )
