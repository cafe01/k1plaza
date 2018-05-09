backoffice.controller 'WebsiteSingle', class WebsiteSingle

    @$inject: ['$element', '$http']
    constructor: (element, @http) ->
        @app = angular.fromJson(angular.element(element).attr('data-app'))
        @users = []
        @hosts = []
        console.log 'WebsiteSingle', @app
        @loadUsers()
        @loadAdmins()
        @loadHosts()

    loadUsers: ->
        @http.get('/.resource/user?appid=' + @app.id).then (res) =>
            if res.data.success
                @users = res.data.items

    loadAdmins: ->
        @http.get('/.resource/user?role=instance_admin&appid=' + @app.id).then (res) =>
            if res.data.success
                @admins = res.data.items

    loadHosts: ->
        @http.get('/.resource/hostname?appid=' + @app.id).then (res) =>
            if res.data.success
                @hosts = res.data.items

    createHostname: ->
        name = prompt('Digite o hostname (www.examplo.com)')
        return unless name
        @http.post('/.resource/hostname?appid=' + @app.id, {name: name}).then (res) =>
            @loadHosts()
        , ->
            alert 'Erro ao criar hostname'

    setHostEnvironment: (host, env) ->
        params = angular.copy host
        params.environment = env
        host.loading = true
        @http.put('/.resource/hostname/' + host.id + '?appid=' + @app.id, params).then (res) =>
            host.loading = false
            console.log 'res', res
            host.environment = env
        , ->
            alert('Erro!')

    setCanonicalHost: (hostname) ->
        @http.put('/.resource/apps/' + @app.id, { canonical_alias: hostname }).then (res) =>
            @app.canonical_alias = hostname
        , ->
            alert('Erro ao salvar canonical_alias')

    deleteHost: (host) ->
        return unless confirm('Remover host "' + host.name + '"?')
        @http.delete('/.resource/hostname/' + host.id + '?appid=' + @app.id).then (res) =>
            @loadHosts()
        , ->
            alert('Erro!')


    addUserRole: (user, roleName) ->
        console.log arguments
        unless roleName
            roleName = prompt('Digite a role a ser adicionada: (ex: instance_admin)')
            return unless roleName

        roles = []
        for r in user.roles
            roles.push r
            return if r.rolename == roleName

        roles.push { rolename: roleName }
        @updateUser(user, { roles: roles }).then =>
            @loadAdmins() if roleName == 'instance_admin'

    removeUserRole: (user, roleName) ->
        askConfimation = true
        unless roleName
            roleName = prompt('Digite a role a ser removida: (ex: instance_admin)')
            return unless roleName
            askConfimation = false

        roles = []
        for r in user.roles
            roles.push r unless r.rolename == roleName

        if askConfimation
            return unless confirm('Remover role?')

        @updateUser(user, { roles: roles }).then =>
            if roleName == 'instance_admin'
                @loadAdmins()
                @loadUsers()

    updateUser: (user, update) ->
        user.loading = true
        promise = @http.put('/.resource/user/' + user.id + '?appid=' + @app.id, update).then (res) =>
            # console.log 'save roles res', res
            user.loading = false
            angular.extend user, update
        , ->
            alert('Erro ao salvar roles')

        promise

    deployRepository: ->
        @http.post('/.resource/apps/deploy_repository?appid=' + @app.id).then (res) =>
            console.log 'deploy_repository', res
        , ->
            console.log 'deploy_repository error:', res
            alert('Erro ao salvar roles')
