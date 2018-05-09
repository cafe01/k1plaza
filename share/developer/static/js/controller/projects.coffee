developer.controller 'Projects', class Projects

    @$inject: ['$http']
    constructor: (@http) ->
        @projects = {}
        @page = 1
        @limit = 10
        @query = ''
        @http.get('/.dev/.resource/settings').then (res) =>
            # if res.data.initial_setup
            #     window.location = "/.dev/config"
            # else
            @ready = true
            @load()

    setLimit: (@limit) -> @load()
    search: ->
        @page = 1
        @load()

    load: ->
        @loading = true
        params =
            page: @page
            limit: @limit
            search: @query

        @http.get('/.dev/.resource/project', params: params).then (res) =>
            @loading = false
            if res.data.items
                projects = res.data
                for project in projects.items
                    if project.git
                        project.git.last_commit.time = moment.unix(project.git.last_commit.time)
                        @repoStatus(project.git)
            @projects = projects

    select: (project, pagePath) ->
        pagePath ||= "/"
        pagePath = "/" + pagePath unless pagePath.match(/^\//)
        console.log pagePath
        @http.post('/.dev/.resource/project/select', name: project.name).then (res) =>
            window.location = pagePath

    repoStatus: (git) ->
        status = {}
        for flag, files of git.status
            if flag.match(/new/)
                status.new ||= []
                status.new.push  files...
            if flag.match(/modified/)
                status.modified ||= []
                status.modified.push  files...
            if flag.match(/deleted/)
                status.deleted ||= []
                status.deleted.push  files...
            if flag.match(/renamed/)
                status.renamed ||= []
                status.renamed.push  files...
            if flag.match(/conflicted/)
                status.conflicted ||= []
                status.conflicted.push  files...

        info = []

        plural = (word, n) => n + " " + word + if n > 1 then "s" else ""

        info.push plural("novo", status.new.length) if status.new
        info.push plural("alterado", status.modified.length) if status.modified
        info.push plural("renomeado", status.renamed.length) if status.renamed
        info.push plural("deletado", status.deleted.length) if status.deleted
        info.push plural("conflitado", status.conflicted.length) if status.conflicted

        # console.log git
        git.status = status
        git.status.isClear = info.length == 0
        git.status.line = if info.length then info.join(', ') else "All clear :)"
