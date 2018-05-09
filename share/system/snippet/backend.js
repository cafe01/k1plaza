
var loaderConfig = {
        enabled: true,
        paths: {
            "Ext.ux": tx.uri_for_static("js/extjs-4.1.1/examples/ux").as_string(),
            "Ext": tx.uri_for_static("js/extjs-4.1.1/src").as_string(),
            "backend": tx.uri_for_static("js/backend").as_string(),
        }
    },
    config = app.config(),
    injectorConfig = config.backend && config.backend.components ? config.backend.components : {};

// add app-specific path
var appName = app.name();
loaderConfig.paths[appName] = tx.uri_for_static('js/'+appName+'/backend').as_string();

element.find('#extjs-loader-config').text('Ext.Loader.setConfig('+JSON.stringify(loaderConfig)+')');


// Injector
injectorConfig.appUrl = { value: tx.uri_for('/').as_string() };

element.find('#deftjs-injector-config').text('Deft.Injector.configure('+JSON.stringify(injectorConfig)+')');
