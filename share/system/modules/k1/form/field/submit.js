var FormField, SubmitField,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

FormField = require("k1/form/field");

module.exports = SubmitField = (function(superClass) {
  extend(SubmitField, superClass);

  function SubmitField(params) {
    params.name = params.name || 'submit';
    params["class"] = params["class"] || 'btn btn-primary';
    SubmitField.__super__.constructor.apply(this, arguments);
    this.type = 'submit';
    this.required = false;
  }

  return SubmitField;

})(FormField);
