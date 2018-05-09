var imageUploader, initContentEditor;

imageUploader = function(dialog) {
  var image;
  image = null;
  dialog.addEventListener('imageuploader.cancelupload', function() {
    return dialog.state('empty');
  });
  dialog.addEventListener('imageuploader.clear', function() {
    dialog.clear();
    return image = null;
  });
  dialog.addEventListener('imageuploader.fileready', function(ev) {
    var file, formData, xhr, xhrComplete, xhrProgress;
    file = ev.detail().file;
    xhrProgress = function(ev) {
      return dialog.progress((ev.loaded / ev.total) * 100);
    };
    xhrComplete = function(ev) {
      if (ev.target.readyState !== 4) {
        return;
      }
      xhrProgress = null;
      xhrComplete = null;
      if (parseInt(ev.target.status) === 200) {
        image = JSON.parse(ev.target.responseText);
        return dialog.populate(image.local_url, [image.width, image.height]);
      } else {
        return new ContentTools.FlashUI('no');
      }
    };
    dialog.state('uploading');
    dialog.progress(0);
    formData = new FormData();
    formData.append('file', file);
    if (window.contentWidthHint) {
      formData.append('maxWidth', window.contentWidthHint.toFixed(0));
    }
    xhr = new XMLHttpRequest();
    xhr.upload.addEventListener('progress', xhrProgress);
    xhr.addEventListener('readystatechange', xhrComplete);
    xhr.open('POST', '/.media', true);
    return xhr.send(formData);
  });
  return dialog.addEventListener('imageuploader.save', function() {
    return dialog.save(image.local_url, [image.width, image.height], {
      'alt': image.file_name,
      'data-ce-max-width': image.width
    });
  });
};

initContentEditor = function() {
  var editor;
  if ($('*[data-editable]').length === 0) {
    return;
  }
  ContentTools.IMAGE_UPLOADER = imageUploader;
  ContentTools.StylePalette.add(new ContentTools.Style('Imagem Responsiva', 'img-responsive', ['img']));
  $.get('/js/k1plaza-editor/content-tools/translations/pt-br.json').then(function(translations) {
    ContentEdit.addTranslations('pt-br', translations);
    return ContentEdit.LANGUAGE = 'pt-br';
  });
  editor = ContentTools.EditorApp.get();
  editor.init('*[data-editable]', 'data-region');
  editor.addEventListener('tool-apply', function(ev) {
    var element;
    element = ev.detail().element;
    window.contentWidthHint = $(element.parent().domElement()).width();
    return console.log('tool-apply', window.contentWidthHint);
  });
  editor.addEventListener('saved', function(ev) {
    var change, changes, content, el, key, onError, onSuccess, params, region, regions;
    regions = ev.detail().regions;
    changes = {};
    for (region in regions) {
      content = regions[region];
      el = $("*[data-region='" + region + "']");
      if (el.attr('data-fixture') != null) {
        content = el.text().replace(/^\s*|\s*$/g, '');
      }
      changes[el.attr('data-editable')] = {
        region: region,
        isFixture: el.attr('data-fixture') != null,
        content: content
      };
    }
    params = {};
    for (key in changes) {
      change = changes[key];
      params[key] = change.content;
    }
    onSuccess = function() {
      var results;
      editor.busy(false);
      new ContentTools.FlashUI('ok');
      results = [];
      for (key in changes) {
        change = changes[key];
        el = $('*[data-editable="' + key + '"][data-region!="' + change.region + '"]');
        if (change.isFixture) {
          results.push(el.text(change.content));
        } else {
          results.push(el.html(change.content));
        }
      }
      return results;
    };
    onError = function() {
      editor.busy(false);
      return new ContentTools.FlashUI('no');
    };
    this.busy(true);
    return $.post("/.content/save", params).then(onSuccess, onError);
  });
  if (window.location.href.match('include_unpublished=1')) {
    return editor._ignition.edit();
  }
};

$(initContentEditor);
