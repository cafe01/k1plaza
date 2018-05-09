

# required param
return console.log '<x-link> error: missing "to=" attribute' if !params.to

# build url
locale = params.lang or tx.locale()
url = tx.site_url_for params.to, locale: locale

# setup element
element.remove_attr 'to'
element.attr 'href', url
element.get(0).setNodeName 'a'
