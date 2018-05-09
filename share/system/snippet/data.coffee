
key = params.name
unless key?
    console.error "<x-data> missing 'name' attribute."
    return

# prepare editable element
element.attr 'data-editable', 'data.' + key
unless params.html
    element.attr 'data-fixture', ''
    element.attr 'data-ce-tag', 'p'

# render value
value = tx.api("Data").get key
if value?
    console.log "Data value:", value
    if params.html
        element.html value
    else
        element.text value
else
    console.log "No value for ", key

# keep x-tag
element.attr('keep-x-tag', 1)
