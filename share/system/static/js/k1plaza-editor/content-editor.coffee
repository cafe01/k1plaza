
imageUploader = (dialog) ->

    # console.log 'init imageUploader', arguments

    image = null

    dialog.addEventListener 'imageuploader.cancelupload', ->
        # Cancel the current upload

        # Stop the upload
        # if (xhr) {
        #     xhr.upload.removeEventListener('progress', xhrProgress)
        #     xhr.removeEventListener('readystatechange', xhrComplete)
        #     xhr.abort()
        # }

        # Set the dialog to empty
        dialog.state('empty')


    dialog.addEventListener 'imageuploader.clear', ->
        # Clear the current image
        dialog.clear()
        image = null


    dialog.addEventListener 'imageuploader.fileready', (ev) ->

        # Upload a file to the server
        file = ev.detail().file

        # Define functions to handle upload progress and completion
        xhrProgress = (ev) ->
            # Set the progress for the upload
            dialog.progress((ev.loaded / ev.total) * 100)

        xhrComplete = (ev) ->
            return unless ev.target.readyState == 4

            # Clear the request
            # xhr = null
            xhrProgress = null
            xhrComplete = null

            # Handle the result of the upload
            if parseInt(ev.target.status) == 200
                image = JSON.parse(ev.target.responseText)
                # console.log 'image', image

                # Populate the dialog
                dialog.populate image.local_url, [image.width, image.height]

            else
                new ContentTools.FlashUI('no')

        # Set the dialog state to uploading and reset the progress bar to 0
        dialog.state('uploading')
        dialog.progress(0)

        # Build the form data to post to the server
        formData = new FormData()
        formData.append('file', file)
        formData.append('maxWidth', window.contentWidthHint.toFixed(0)) if window.contentWidthHint

        # Make the request
        xhr = new XMLHttpRequest()
        xhr.upload.addEventListener('progress', xhrProgress)
        xhr.addEventListener('readystatechange', xhrComplete)
        xhr.open('POST', '/.media', true)
        xhr.send(formData)


    dialog.addEventListener 'imageuploader.save', ->

        dialog.save( image.local_url, [image.width, image.height], {
            'alt': image.file_name
            'data-ce-max-width': image.width
        })

initContentEditor = ->
    return if $('*[data-editable]').length == 0

    ContentTools.IMAGE_UPLOADER = imageUploader

    ContentTools.StylePalette.add(
        new ContentTools.Style('Imagem Responsiva', 'img-responsive', ['img'])
    )

    $.get('/js/k1plaza-editor/content-tools/translations/pt-br.json').then (translations) ->
        ContentEdit.addTranslations('pt-br', translations)
        ContentEdit.LANGUAGE = 'pt-br'


    editor = ContentTools.EditorApp.get()
    editor.init('*[data-editable]', 'data-region')

    editor.addEventListener 'tool-apply', (ev) ->
        element = ev.detail().element
        window.contentWidthHint = $(element.parent().domElement()).width()
        console.log 'tool-apply', window.contentWidthHint



    editor.addEventListener 'saved', (ev) ->
        regions = ev.detail().regions
        # console.log 'regions', regions

        changes = {}
        for region, content of regions
            el = $("*[data-region='" + region + "']")
            content = el.text().replace(/^\s*|\s*$/g, '') if el.attr('data-fixture')?
            changes[el.attr('data-editable')] =
                region: region
                isFixture: el.attr('data-fixture')?
                content: content

        # console.log 'changes', changes
        params = {}
        for key, change of changes
            params[key] = change.content

        # console.log 'params', params

        onSuccess = ->
            editor.busy(false)
            new ContentTools.FlashUI('ok')

            # reflect change to other elements
            for key, change of changes
                el = $('*[data-editable="' + key + '"][data-region!="' + change.region + '"]')
                if change.isFixture
                    el.text(change.content)
                else
                    el.html(change.content)

        # error callback
        onError = ->
            editor.busy(false)
            new ContentTools.FlashUI('no')

        # send
        @busy(true)
        $.post("/.content/save", params).then(onSuccess, onError)

    # auto start
    # console.log 'editor', editor
    if window.location.href.match('include_unpublished=1')
        editor._ignition.edit()




$(initContentEditor)
