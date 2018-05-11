var Form;

Form = require('k1/form');

module.exports = function() {
  return new Form({
    fields: ["name", "email", "submit:submit"],
    action: function(values) {
      return values;
    }
  });
};
