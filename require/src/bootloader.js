config = {
    paths: {
        cs: 'libs/requirejs/cs',
        domReady: 'libs/requirejs/domReady',
        hb: 'libs/requirejs/hb',
        less: 'libs/requirejs/less',
        order: 'libs/requirejs/order',
        text: 'libs/requirejs/text'
    },
    waitSeconds: 5,
    baseUrl: "."
}

// if (environ==="DEPLOY") {
	// config.baseUrl = "build"
// } else {
	// config.baseUrl = "src"
// }

require.config(config)

// require all the non-AMD libraries, in order, to be bundled with the AMD modules
define(
	[
		"order!libs/jquery/jquery",
		"order!libs/jquery/jquery-ui",
		"order!libs/jquery/jquery.jeditable",
		"order!libs/jquery/jquery.watermark",
		"order!libs/json2",
		"order!libs/backbone/backbone",
		"order!libs/backbone/backbone-relational",
		"order!libs/backbone/backbone.memento",
		"order!libs/backbone/backbone.modelbinding",
		"order!libs/handlebars/wrapper",
		"order!libs/bootstrap/bootstrap-buttons",
		"order!libs/fancybox/jquery.fancybox-1.3.4",
		"order!libs/ckeditor/ckeditor",
		"order!libs/ckeditor/adapters/jquery",
		"cs!app"
	], function() {
		require("cs!app").initialize()
	}
)
    
