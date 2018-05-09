var locale, url;

if (!params.to) {
  return console.log('<x-link> error: missing "to=" attribute');
}

locale = params.lang || tx.locale();

url = tx.site_url_for(params.to, {
  locale: locale
});

element.remove_attr('to');

element.attr('href', url);

element.get(0).setNodeName('a');
