developer.controller('Projects', (_a = /** @class */ (function () {
        function Projects(http, modal, scope) {
            var _this = this;
            this.http = null;
            this.modal = null;
            this.scope = null;
            this.ready = false;
            this.settings = null;
            this.loading = false;
            this.projects = {};
            this.page = 1;
            this.limit = 10;
            this.query = '';
            this.http = http;
            this.modal = modal;
            this.scope = scope;
            http.get('/.dev/.resource/settings').then(function (res) {
                _this.ready = true;
                _this.load();
            });
        }
        Projects.prototype.setLimit = function (limit) {
            this.limit = limit;
            this.load();
        };
        Projects.prototype.search = function () {
            this.page = 1;
            this.load();
        };
        Projects.prototype.load = function () {
            var _this = this;
            this.loading = true;
            var params = {
                page: this.page,
                limit: this.limit,
                search: this.query
            };
            this.http.get('/.dev/.resource/project', { params: params }).then(function (res) {
                _this.loading = false;
                var projects = res.data;
                if (projects.items) {
                    for (var _i = 0, _a = projects.items; _i < _a.length; _i++) {
                        var project = _a[_i];
                        if (!project.git)
                            continue;
                        project.git.last_commit.time = moment.unix(project.git.last_commit.time);
                    }
                }
                _this.projects = projects;
            });
        };
        Projects.prototype.chooseStarter = function () {
            location.replace("/.dev/starters");
        };
        Projects.prototype.select = function (project, pagePath) {
            if (pagePath === void 0) { pagePath = "/"; }
            if (!pagePath.match(/^\//))
                pagePath = "/" + pagePath;
            this.http.post('/.dev/.resource/project/select', { base_dir: project.base_dir })
                .then(function () {
                if (typeof document.body.animate != "function") {
                    location.replace(pagePath);
                    return;
                }
                var animation = document.body.animate([{ opacity: 1 }, { opacity: 0 }], { duration: 150, fill: "forwards" });
                animation.onfinish = function () { return location.replace(pagePath); };
            });
        };
        return Projects;
    }()),
    _a.$inject = ['$http', '$uibModal', '$rootScope'],
    _a));
var _a;
