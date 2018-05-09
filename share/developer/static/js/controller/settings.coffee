developer.controller 'Settings', class Settings

    @$inject: ['$http']
    constructor: (@http) ->
        @wizardPage = 0

        @http.get('/.dev/.resource/settings').then (res) =>
            @settings = res.data
            @user = @settings.github_account
            if @settings.disable_autologin == undefined
                @settings.disable_autologin = 0
            # console.log 'settings controller', @settings

    updateAccessToken: (token) ->
        @loading = true
        params = angular.copy @settings
        delete params.initial_setup
        params.github_access_token = token
        @http.post('/.dev/.resource/settings/token', token: token).then (res) =>
            window.location = '/.dev/config'
        , =>
            @loading = false
            alert "Token inválido."

    save: ->
        @loading = true
        @http.post('/.dev/.resource/settings', @settings).then (res) ->
            @loading = false
            console.log "Settings saved!"

    resetSettings: ->
        @loading = true
        @http.post('/.dev/.resource/settings', {}).then (res) =>
            window.location = '/.dev/config'
