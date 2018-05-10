var FormField,
  slice = [].slice;

module.exports = FormField = (function() {
  var htmlAttributes;

  htmlAttributes = ['name', 'type', 'id', 'class', 'placeholder', 'value', 'title'];

  FormField.prototype.tag = 'input';

  FormField.prototype.wrapper = {
    tag: 'div',
    "class": ''
  };

  function FormField(params) {
    var attr, i, len, match, ref;
    params = typeof params === "object" ? params : {
      name: params
    };
    this.name = params.name;
    if (!this.name) {
      console.error("[FormField] missing 'name' config");
      throw "missing form field 'name'";
    }
    if (!(this.type = params.type)) {
      if (match = this.name.match(/(\w+):(\w+)/)) {
        this.name = match[1];
        this.type = match[2];
      } else {
        this.type = 'text';
      }
    }
    this.required = typeof params.required === "boolean" ? params.required : true;
    ref = ['label'].concat(slice.call(htmlAttributes));
    for (i = 0, len = ref.length; i < len; i++) {
      attr = ref[i];
      if ((this[attr] == null) && (params[attr] != null)) {
        this[attr] = params[attr];
      }
    }
  }

  FormField.prototype.render = function() {
    var $, attr, element, i, len;
    $ = require('k1/jquery');
    element = $("<" + this.tag + " />");
    for (i = 0, len = htmlAttributes.length; i < len; i++) {
      attr = htmlAttributes[i];
      if (this[attr]) {
        element.attr(attr, this[attr]);
      }
    }
    if (this.required) {
      element.attr('required', 'required');
    }
    return element;
  };

  return FormField;

})();
