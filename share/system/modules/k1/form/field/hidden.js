var FormField, HiddenField,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

FormField = require("k1/form/field");

module.exports = HiddenField = (function(superClass) {
  extend(HiddenField, superClass);

  function HiddenField() {
    HiddenField.__super__.constructor.apply(this, arguments);
    this.type = 'hidden';
    this.wrapper = null;
  }

  return HiddenField;

})(FormField);
