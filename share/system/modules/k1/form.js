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
    var HiddenField, field, ref;
    config = config || {};
    this.name = config.name || this.name || 'defultName';
    this.fields = this.fields || [];
    if (Array.isArray(config.fields)) {
      (ref = this.fields).push.apply(ref, config.fields);
    }
    this.fields = (function() {
      var i, len, ref1, results;
      ref1 = this.fields;
      results = [];
      for (i = 0, len = ref1.length; i < len; i++) {
        field = ref1[i];
        results.push(_createField(field));
      }
      return results;
    }).call(this);
    HiddenField = require('k1/form/field/hidden');
    this.fields.push(new HiddenField({
      name: '_csrf'
    }));
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
      if (field.required && ((value == null) || !value.match(/\w/))) {
        errors.push({
          message: "Campo obrigatório",
          field: field.name
        });
        continue;
      }
      valid[field.name] = value;
      field.setValue(value);
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

  Form.prototype.render = function(element) {
    var $, field, fieldEl, formEl, i, j, len, len1, ref, ref1;
    $ = require('k1/jquery');
    formEl = element || $('<form/>');
    formEl.attr({
      action: "/.form/" + this.name,
      method: "post",
      name: this.name
    });
    if (formEl.find('input, textarea').size() === 0) {
      ref = this.fields;
      for (i = 0, len = ref.length; i < len; i++) {
        field = ref[i];
        field.render().append_to(formEl);
      }
    } else {
      ref1 = this.fields;
      for (j = 0, len1 = ref1.length; j < len1; j++) {
        field = ref1[j];
        fieldEl = formEl.find("*[name='" + field.name + "']");
        if (!fieldEl.size()) {
          continue;
        }
        field.fillElement(fieldEl);
      }
      if (formEl.find('input[name="_csrf"]').size() === 0) {
        this.getField("_csrf").render().append_to(formEl);
      }
    }
    return formEl;
  };

  return Form;

})();
