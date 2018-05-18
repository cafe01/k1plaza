declare var developer:any

developer.controller('Starters', class Starters {

    static $inject = ['$http', '$uibModal', '$rootScope']

    http = null
    modal = null
    repos = [
        { full_name: 'cafe01/k1plaza-starter-blank' },
        { full_name: 'cafe01/k1plaza-bootstrap4-components' }
    ]

    loading = false
    ready = false
    settings = null
    scope = null
    focused = null

    constructor(http, modal, scope) {
        this.http  = http
        this.modal = modal
        this.scope = scope

        http.get('/.dev/.resource/settings').then((res) => {
            this.ready = true
            this.settings = res.data
            this.repos.forEach((r) => this.load(r))
        }) 
    }

    load(repo) {
        let http = this.http
        let settings = this.settings
        
        if (settings.github_access_token) {
            http.defaults.headers.common.Authorization = `token ${settings.github_access_token}`
        }
        
        this.loading = true
        http.get(`https://api.github.com/repos/${repo.full_name}`)
            .then((res) => angular.merge(repo, res.data), (res) => {
                console.error('repo error', res)
                repo.error = res.data.message || 'Erro!'
            })
    }

    startProject (params, repo) {
 
        let ws = new WebSocket(`ws://${window.location.host}/.dev/.resource/project/ws/create`)
        repo.newProject.progress = {}
        repo.newProject.result = null

        ws.onopen = () => {
            // console.log("ws open")
            ws.send(JSON.stringify({ 
                ...params,
                repository_name: repo.full_name
            }))
        }

        ws.onclose = () => {
            let result = repo.newProject.result
            console.log("result", result)
        }

        ws.onmessage = (msg) => {
            let data = JSON.parse(msg.data)
            // console.log(data)
            switch(data.type) {
                case "transfer_progress":
                    data.percent = Math.ceil(data.received_objects * 100 / data.total_objects)
                    angular.merge(repo.newProject.progress, data)
                    // console.log(project.progress)
                    break
                case "sideband_progress":
                    repo.newProject.progress.message = data.message
                    break
                case "result":
                    repo.newProject.result = data
            }

            this.scope.$digest()
        }
    }

    openProject(project) {
        project.opening = true
        
        this.http
            .post('/.dev/.resource/project/select', { base_dir: project.result.project_base_dir })
            .then(
                () => location.replace("/"),
                (res) => console.error("error selecting project", res)
            )                
    }
})