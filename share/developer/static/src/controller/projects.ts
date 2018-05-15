declare var developer:any

developer.controller('Projects', class Projects {

    static $inject = ['$http', '$uibModal', '$rootScope']

    http = null
    modal = null
    scope = null

    ready = false
    settings = null
    loading = false
    projects = {}
    page = 1
    limit = 10
    query = ''

    constructor(http, modal, scope) {
        this.http  = http
        this.modal = modal
        this.scope = scope

        http.get('/.dev/.resource/settings').then((res) => {
            this.ready = true
            this.load()
        }) 
    }

    setLimit(limit) {
        this.limit = limit
        this.load()
    }

    search () {
        this.page = 1
        this.load()
    }

    load() {
        this.loading = true

        let params = {
            page: this.page,
            limit: this.limit,
            search: this.query
        }

        this.http.get('/.dev/.resource/project', {params: params}).then((res) => {
            this.loading = false
            let projects = res.data

            if (projects.items) {

                for (let project of projects.items) {

                    if (!project.git) continue
                    project.git.last_commit.time = moment.unix(project.git.last_commit.time)
                }
            }

            this.projects = projects
        });
    }

    select (project, pagePath = "/") {

        if (!pagePath.match(/^\//)) pagePath = "/" + pagePath 

        this.http.post('/.dev/.resource/project/select', {base_dir: project.base_dir})
                 .then(() => location.replace(pagePath))
    }

})