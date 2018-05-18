var __assign = (this && this.__assign) || Object.assign || function(t) {
    for (var s, i = 1, n = arguments.length; i < n; i++) {
        s = arguments[i];
        for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p))
            t[p] = s[p];
    }
    return t;
};
developer.controller('Starters', (_a = /** @class */ (function () {
        function Starters(http, modal, scope) {
            var _this = this;
            this.http = null;
            this.modal = null;
            this.repos = [
                { full_name: 'cafe01/k1plaza-starter-blank' },
                { full_name: 'cafe01/k1plaza-bootstrap4-components' }
            ];
            this.loading = false;
            this.ready = false;
            this.settings = null;
            this.scope = null;
            this.focused = null;
            this.http = http;
            this.modal = modal;
            this.scope = scope;
            http.get('/.dev/.resource/settings').then(function (res) {
                _this.ready = true;
                _this.settings = res.data;
                _this.repos.forEach(function (r) { return _this.load(r); });
            });
        }
        Starters.prototype.load = function (repo) {
            var http = this.http;
            var settings = this.settings;
            if (settings.github_access_token) {
                http.defaults.headers.common.Authorization = "token " + settings.github_access_token;
            }
            this.loading = true;
            http.get("https://api.github.com/repos/" + repo.full_name)
                .then(function (res) { return angular.merge(repo, res.data); }, function (res) {
                console.error('repo error', res);
                repo.error = res.data.message || 'Erro!';
            });
        };
        Starters.prototype.startProject = function (params, repo) {
            var _this = this;
            var ws = new WebSocket("ws://" + window.location.host + "/.dev/.resource/project/ws/create");
            repo.newProject.progress = {};
            repo.newProject.result = null;
            ws.onopen = function () {
                // console.log("ws open")
                ws.send(JSON.stringify(__assign({}, params, { repository_name: repo.full_name })));
            };
            ws.onclose = function () {
                var result = repo.newProject.result;
                console.log("result", result);
            };
            ws.onmessage = function (msg) {
                var data = JSON.parse(msg.data);
                // console.log(data)
                switch (data.type) {
                    case "transfer_progress":
                        data.percent = Math.ceil(data.received_objects * 100 / data.total_objects);
                        angular.merge(repo.newProject.progress, data);
                        // console.log(project.progress)
                        break;
                    case "sideband_progress":
                        repo.newProject.progress.message = data.message;
                        break;
                    case "result":
                        repo.newProject.result = data;
                }
                _this.scope.$digest();
            };
        };
        Starters.prototype.openProject = function (project) {
            project.opening = true;
            this.http
                .post('/.dev/.resource/project/select', { base_dir: project.result.project_base_dir })
                .then(function () { return location.replace("/"); }, function (res) { return console.error("error selecting project", res); });
        };
        return Starters;
    }()),
    _a.$inject = ['$http', '$uibModal', '$rootScope'],
    _a));
var _a;
