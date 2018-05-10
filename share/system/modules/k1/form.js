var Form;

module.exports = Form = (function() {
  var _createField;

  _createField = function(params) {
    var FieldClass, match;
    params = typeof params === "object" ? params : {
      name: params
    };
    if (!(params.type = params.type)) {
      if ((params.name != null) && (match = params.name.match(/(\w+):(\w+)/))) {
        params.name = match[1];
        params.type = match[2];
      } else {
        params.type = 'text';
      }
    }
    try {
      FieldClass = require("k1/form/field/" + params.type);
    } catch (error) {
      console.error("[Form] error loading field type '" + params.type + "'");
      throw "invalid field";
    }
    return new FieldClass(params);
  };

  function Form(config) {
    var f, field;
    config = config || {};
    this.name = config.name || 'defultName';
    this.fields = [];
    if (Array.isArray(config.fields)) {
      this.fields = (function() {
        var i, len, ref, results;
        ref = config.fields;
        results = [];
        for (i = 0, len = ref.length; i < len; i++) {
          f = ref[i];
          field = _createField(f);
          results.push(field);
        }
        return results;
      })();
    }
    if (typeof config.action === "function") {
      this.action = config.action;
    }
  }

  Form.prototype.action = function() {
    return console.log("default action() called on form ", this.name);
  };

  Form.prototype.getField = function(name) {
    var field, i, len, ref;
    ref = this.fields;
    for (i = 0, len = ref.length; i < len; i++) {
      field = ref[i];
      if (field.name === name) {
        return field;
      }
    }
  };

  Form.prototype.process = function(values) {
    var errors, field, i, len, ref, valid, value;
    errors = [];
    valid = {};
    ref = this.fields;
    for (i = 0, len = ref.length; i < len; i++) {
      field = ref[i];
      value = values[field.name];
      if (field.required && (value == null)) {
        errors.push({
          message: "Campo obrigatório",
          field: field.name
        });
        continue;
      }
      valid[field.name] = value;
      this.getField(field.name).value = value;
    }
    this.processed = true;
    this.isValid = errors.length === 0;
    if (this.isValid) {
      return {
        success: true,
        fields: valid
      };
    } else {
      return {
        success: false,
        errors: errors
      };
    }
  };

  Form.prototype.render = function() {
    var $, field, form, i, len, ref;
    $ = require('k1/jquery');
    form = $('<form/>');
    form.attr({
      action: "/.form/" + this.name,
      name: this.name
    });
    ref = this.fields;
    for (i = 0, len = ref.length; i < len; i++) {
      field = ref[i];
      field.render().append_to(form);
    }
    return form;
  };

  return Form;

})();
