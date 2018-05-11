var FormField, TextAreaField,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

FormField = require("k1/form/field");

module.exports = TextAreaField = (function(superClass) {
  extend(TextAreaField, superClass);

  function TextAreaField() {
    TextAreaField.__super__.constructor.apply(this, arguments);
    this.type = 'textarea';
    this.tag = 'textarea';
  }

  TextAreaField.prototype.render = function() {
    var el;
    el = TextAreaField.__super__.render.call(this);
    el.text(this.value);
    return el.remove_attr('value');
  };

  return TextAreaField;

})(FormField);
