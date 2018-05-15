developer.controller('Settings', (_a = /** @class */ (function () {
        function Settings(http) {
            var _this = this;
            this.http = null;
            this.loading = false;
            this.settings = null;
            this.user = null;
            this.wizardPage = 0;
            this.http = http;
            http.get('/.dev/.resource/settings').then(function (res) {
                _this.settings = res.data;
                _this.user = _this.settings.github_account;
                if (_this.settings.disable_autologin == undefined)
                    _this.settings.disable_autologin = 0;
            });
        }
        Settings.prototype.updateAccessToken = function (token) {
            var _this = this;
            this.loading = true;
            var params = angular.copy(this.settings);
            delete params.initial_setup;
            params.github_access_token = token;
            this.http.post('/.dev/.resource/settings/token', { token: token }).then(function () { return location.replace("/.dev/config"); }, function () {
                _this.loading = false;
                alert("Token inválido.");
            });
        };
        Settings.prototype.save = function () {
            var _this = this;
            this.loading = true;
            this.http.post('/.dev/.resource/settings', this.settings).then(function () {
                _this.loading = false;
                console.log("Settings saved!");
            }, function (res) {
                console.error("error saving settings", res);
            });
        };
        Settings.prototype.resetSettings = function () {
            var _this = this;
            this.loading = true;
            this.http.post('/.dev/.resource/settings', {}).then(function () { return location.replace("/.dev/config"); }, function () {
                _this.loading = false;
                console.error("error reseting settings");
            });
        };
        return Settings;
    }()),
    _a.$inject = ['$http'],
    _a));
var _a;
