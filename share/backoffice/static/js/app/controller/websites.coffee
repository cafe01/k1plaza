backoffice.controller 'Websites', class Websites

    @$inject: ['$http']
    constructor: (@http) ->
        console.log 'Websites controller'
        @websites = []
        @load()

    load: ->
        @loading = true
        @http.get('/.resource/apps').then (res) =>
            @loading = false 
            if res.data.success
                @websites = for item in res.data.items
                    item.created_at = moment item.created_at
                    item.is_managed = parseInt item.is_managed
                    item

    newApp: ->
        @newApp =
            name: ''
            hostnames: [{ name: null, environment: 'production' }]

        @showCreateApp = true

    newAppHostname: ->
        @newApp.hostnames.push { name: null }

    createApp: ->
        params =
            name: @newApp.name
            repository_url: @newApp.repository_url
            hostnames: []

        for item in @newApp.hostnames
            params.hostnames.push item if item.name?

        @newAppError = false
        @http.post('/.resource/apps', params).then (res) =>
            app = res.data.items
            app.hightlight = 'info'
            @websites.unshift app
            @showCreateApp = false
        , (res) =>
            @newAppError = true

    deployRepo: ->
        @loading = true
        @http.get('/.resource/devops/update_repo').then =>
            @loading = false
        , ->
            @loading = false
            alert("Erro!")
