var FormLoader;

FormLoader = (function() {
  function FormLoader() {}

  FormLoader.prototype.load = function(formName, formConfig) {
    var FormClass, form;
    if (formConfig == null) {
      formConfig = {};
    }
    try {
      FormClass = require("form/" + formName);
      if (typeof FormClass !== "function") {
        formConfig = FormClass;
        FormClass = require("k1/form");
      }
      formConfig.name = formName;
      form = new FormClass(formConfig);
    } catch (error) {
      console.error("error loading form '" + formName + "'");
      throw "invalid form: '" + formName + "'";
    }
    return form;
  };

  return FormLoader;

})();

module.exports = new FormLoader();
