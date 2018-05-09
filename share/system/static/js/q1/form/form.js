

(function($) {

    $.fn.q1_form = function(options) {

        var config = $.extend({

            hideOnSuccess : true,
            fieldErrorTemplate: '<span class="error_message"></span>',
            fieldErrorSelector: '.error_message',
            waitingClass: 'waiting-form',
            fieldErrorClass: 'error',
            onError: null

        }, options || {});

        function onFormSuccess(form, res) {

            if (typeof res == 'string') {
                try { res = $.parseJSON(res) }
                catch(e) { return console.log('error parsing response', e) }
            }

            if (res.success) {

                if (config.hideOnSuccess) {
                    form.hide();
                }

                // show suscces msg and back button
                $('.form-' + form.attr('name') + '-success').fadeIn();
                $('#back-button').show();

            } else {


                var errorTemplate = $('.form-' + form.attr('name') + '-error').first(),
                    errorList = errorTemplate.parent();

                if (typeof config.onError == 'function') {
                    config.onError(form, res);
                }

                // error list
                if (errorTemplate.length > 0) {
                    $.each(res.errors, function(i, errorMsg) {
                        errorTemplate.clone().html(errorMsg).appendTo(errorList).fadeIn();
                    });
                }

                // field error
                $.each(res.error_fields || {}, function(fieldName, fieldErrors) {
                    var errorEl = $(config.fieldErrorTemplate).html(fieldErrors[0]);

                    form.find('[name='+fieldName+']')
                        .after(errorEl)
                        .parent().addClass(config.fieldErrorClass);
                });
            }
        }

        function legacySubmitForm(form) {


            //start the ajax
            $.ajax({
                url : form.attr('action'),
                type : "post",
                data : form.serialize(),
                cache : false,
                success : function(res) {

                    // remove wait class
                    $('body').removeClass(config.waitingClass);

                    onFormSuccess(form, res);
                }
            });
        }

        function submitForm(form) {

            var xhr = new XMLHttpRequest(),
                url = form.attr('action') || window.location.toString();

            xhr.onload = function(e) {

                // remove wait class
                $('body').removeClass(config.waitingClass);

                // real error
                if (xhr.status >= 300 || xhr.status < 200) {
                    return console.erro('error subminting form: bad http stats: '+ xhr.status);
                }

                onFormSuccess(form, xhr.responseText);
            };


            // create data
            var formData = new FormData(form[0]);

            form.find('input[type=file][name]').each(function(i, fileInput){
                $.each(fileInput.files, function(i, file){
                    formData.append(fileInput.name, file);
                });
            });


            // console.log('form data', data, formData);
            xhr.open('POST', url, true);
            xhr.setRequestHeader('Accept', 'application/json');
            xhr.setRequestHeader('X-AJAX', '1');
            xhr.send(formData);
        }


        return this.each(function() {

            var form = $(this),
                errorTemplate = $('.form-' + form.attr('name') + '-error').first(),
                errorList = errorTemplate.parent();

            form.submit(function(evt) {

                evt.preventDefault();
                evt.stopPropagation();

                // reset error state before submit
                errorList.empty();
                form.find('input,textarea').parent().removeClass(config.fieldErrorClass);
                form.find(config.fieldErrorSelector).remove();

                // add wait class
                $('body').addClass(config.waitingClass);

                // send
                if (window.FormData) {
                    submitForm(form);
                }
                else {
                    legacySubmitForm(form);
                }



            });
        });
    };

})(jQuery);
