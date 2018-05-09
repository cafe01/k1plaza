var Projects;

developer.controller('Projects', Projects = (function() {
  Projects.$inject = ['$http'];

  function Projects(http) {
    this.http = http;
    this.projects = {};
    this.page = 1;
    this.limit = 10;
    this.query = '';
    this.http.get('/.dev/.resource/settings').then((function(_this) {
      return function(res) {
        _this.ready = true;
        return _this.load();
      };
    })(this));
  }

  Projects.prototype.setLimit = function(limit) {
    this.limit = limit;
    return this.load();
  };

  Projects.prototype.search = function() {
    this.page = 1;
    return this.load();
  };

  Projects.prototype.load = function() {
    var params;
    this.loading = true;
    params = {
      page: this.page,
      limit: this.limit,
      search: this.query
    };
    return this.http.get('/.dev/.resource/project', {
      params: params
    }).then((function(_this) {
      return function(res) {
        var i, len, project, projects, ref;
        _this.loading = false;
        if (res.data.items) {
          projects = res.data;
          ref = projects.items;
          for (i = 0, len = ref.length; i < len; i++) {
            project = ref[i];
            if (project.git) {
              project.git.last_commit.time = moment.unix(project.git.last_commit.time);
              _this.repoStatus(project.git);
            }
          }
        }
        return _this.projects = projects;
      };
    })(this));
  };

  Projects.prototype.select = function(project, pagePath) {
    pagePath || (pagePath = "/");
    if (!pagePath.match(/^\//)) {
      pagePath = "/" + pagePath;
    }
    console.log(pagePath);
    return this.http.post('/.dev/.resource/project/select', {
      name: project.name
    }).then((function(_this) {
      return function(res) {
        return window.location = pagePath;
      };
    })(this));
  };

  Projects.prototype.repoStatus = function(git) {
    var files, flag, info, plural, ref, ref1, ref2, ref3, ref4, ref5, status;
    status = {};
    ref = git.status;
    for (flag in ref) {
      files = ref[flag];
      if (flag.match(/new/)) {
        status["new"] || (status["new"] = []);
        (ref1 = status["new"]).push.apply(ref1, files);
      }
      if (flag.match(/modified/)) {
        status.modified || (status.modified = []);
        (ref2 = status.modified).push.apply(ref2, files);
      }
      if (flag.match(/deleted/)) {
        status.deleted || (status.deleted = []);
        (ref3 = status.deleted).push.apply(ref3, files);
      }
      if (flag.match(/renamed/)) {
        status.renamed || (status.renamed = []);
        (ref4 = status.renamed).push.apply(ref4, files);
      }
      if (flag.match(/conflicted/)) {
        status.conflicted || (status.conflicted = []);
        (ref5 = status.conflicted).push.apply(ref5, files);
      }
    }
    info = [];
    plural = (function(_this) {
      return function(word, n) {
        return n + " " + word + (n > 1 ? "s" : "");
      };
    })(this);
    if (status["new"]) {
      info.push(plural("novo", status["new"].length));
    }
    if (status.modified) {
      info.push(plural("alterado", status.modified.length));
    }
    if (status.renamed) {
      info.push(plural("renomeado", status.renamed.length));
    }
    if (status.deleted) {
      info.push(plural("deletado", status.deleted.length));
    }
    if (status.conflicted) {
      info.push(plural("conflitado", status.conflicted.length));
    }
    git.status = status;
    git.status.isClear = info.length === 0;
    return git.status.line = info.length ? info.join(', ') : "All clear :)";
  };

  return Projects;

})());
