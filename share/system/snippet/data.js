var key, value;

key = params.name;

if (key == null) {
  console.error("<x-data> missing 'name' attribute.");
  return;
}

element.attr('data-editable', 'data.' + key);

if (!params.html) {
  element.attr('data-fixture', '');
  element.attr('data-ce-tag', 'p');
}

value = tx.api("Data").get(key);

if (value != null) {
  // console.log("Data value:", value);
  if (params.html) {
    element.html(value);
  } else {
    element.text(value);
  }
} else {
  // console.log("No value for ", key);
}

element.attr('keep-x-tag', 1);
