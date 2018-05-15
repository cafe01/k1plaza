declare var developer:any

developer.controller('Settings', class Settings {

    static $inject = ['$http']

    http = null

    loading = false
    settings = null
    user = null    
    wizardPage = 0

    constructor(http) {
        this.http  = http

        http.get('/.dev/.resource/settings').then((res) => {
            this.settings = res.data
            this.user = this.settings.github_account
            if (this.settings.disable_autologin == undefined) this.settings.disable_autologin = 0
        }) 
    }

    updateAccessToken(token) {

        this.loading = true
        let params = angular.copy(this.settings)
        delete params.initial_setup
        params.github_access_token = token
        this.http.post('/.dev/.resource/settings/token', {token: token}).then(
            () => location.replace("/.dev/config"),
            () => {
                this.loading = false
                alert("Token inválido.")
            }
        )
    }

    save() {

        this.loading = true
        this.http.post('/.dev/.resource/settings', this.settings).then(() => {
            this.loading = false
            console.log("Settings saved!")
        }, (res) => {
            console.error("error saving settings", res)
        })
    }

    resetSettings() {

        this.loading = true
        this.http.post('/.dev/.resource/settings', {}).then(
            () => location.replace("/.dev/config"),
            () => {
                this.loading = false
                console.error("error reseting settings")
            }
        )
    }


})
