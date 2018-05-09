var WebsiteSingle;

backoffice.controller('WebsiteSingle', WebsiteSingle = (function() {
  WebsiteSingle.$inject = ['$element', '$http'];

  function WebsiteSingle(element, http) {
    this.http = http;
    this.app = angular.fromJson(angular.element(element).attr('data-app'));
    this.users = [];
    this.hosts = [];
    console.log('WebsiteSingle', this.app);
    this.loadUsers();
    this.loadAdmins();
    this.loadHosts();
  }

  WebsiteSingle.prototype.loadUsers = function() {
    return this.http.get('/.resource/user?appid=' + this.app.id).then((function(_this) {
      return function(res) {
        if (res.data.success) {
          return _this.users = res.data.items;
        }
      };
    })(this));
  };

  WebsiteSingle.prototype.loadAdmins = function() {
    return this.http.get('/.resource/user?role=instance_admin&appid=' + this.app.id).then((function(_this) {
      return function(res) {
        if (res.data.success) {
          return _this.admins = res.data.items;
        }
      };
    })(this));
  };

  WebsiteSingle.prototype.loadHosts = function() {
    return this.http.get('/.resource/hostname?appid=' + this.app.id).then((function(_this) {
      return function(res) {
        if (res.data.success) {
          return _this.hosts = res.data.items;
        }
      };
    })(this));
  };

  WebsiteSingle.prototype.createHostname = function() {
    var name;
    name = prompt('Digite o hostname (www.examplo.com)');
    if (!name) {
      return;
    }
    return this.http.post('/.resource/hostname?appid=' + this.app.id, {
      name: name
    }).then((function(_this) {
      return function(res) {
        return _this.loadHosts();
      };
    })(this), function() {
      return alert('Erro ao criar hostname');
    });
  };

  WebsiteSingle.prototype.setHostEnvironment = function(host, env) {
    var params;
    params = angular.copy(host);
    params.environment = env;
    host.loading = true;
    return this.http.put('/.resource/hostname/' + host.id + '?appid=' + this.app.id, params).then((function(_this) {
      return function(res) {
        host.loading = false;
        console.log('res', res);
        return host.environment = env;
      };
    })(this), function() {
      return alert('Erro!');
    });
  };

  WebsiteSingle.prototype.setCanonicalHost = function(hostname) {
    return this.http.put('/.resource/apps/' + this.app.id, {
      canonical_alias: hostname
    }).then((function(_this) {
      return function(res) {
        return _this.app.canonical_alias = hostname;
      };
    })(this), function() {
      return alert('Erro ao salvar canonical_alias');
    });
  };

  WebsiteSingle.prototype.deleteHost = function(host) {
    if (!confirm('Remover host "' + host.name + '"?')) {
      return;
    }
    return this.http["delete"]('/.resource/hostname/' + host.id + '?appid=' + this.app.id).then((function(_this) {
      return function(res) {
        return _this.loadHosts();
      };
    })(this), function() {
      return alert('Erro!');
    });
  };

  WebsiteSingle.prototype.addUserRole = function(user, roleName) {
    var i, len, r, ref, roles;
    console.log(arguments);
    if (!roleName) {
      roleName = prompt('Digite a role a ser adicionada: (ex: instance_admin)');
      if (!roleName) {
        return;
      }
    }
    roles = [];
    ref = user.roles;
    for (i = 0, len = ref.length; i < len; i++) {
      r = ref[i];
      roles.push(r);
      if (r.rolename === roleName) {
        return;
      }
    }
    roles.push({
      rolename: roleName
    });
    return this.updateUser(user, {
      roles: roles
    }).then((function(_this) {
      return function() {
        if (roleName === 'instance_admin') {
          return _this.loadAdmins();
        }
      };
    })(this));
  };

  WebsiteSingle.prototype.removeUserRole = function(user, roleName) {
    var askConfimation, i, len, r, ref, roles;
    askConfimation = true;
    if (!roleName) {
      roleName = prompt('Digite a role a ser removida: (ex: instance_admin)');
      if (!roleName) {
        return;
      }
      askConfimation = false;
    }
    roles = [];
    ref = user.roles;
    for (i = 0, len = ref.length; i < len; i++) {
      r = ref[i];
      if (r.rolename !== roleName) {
        roles.push(r);
      }
    }
    if (askConfimation) {
      if (!confirm('Remover role?')) {
        return;
      }
    }
    return this.updateUser(user, {
      roles: roles
    }).then((function(_this) {
      return function() {
        if (roleName === 'instance_admin') {
          _this.loadAdmins();
          return _this.loadUsers();
        }
      };
    })(this));
  };

  WebsiteSingle.prototype.updateUser = function(user, update) {
    var promise;
    user.loading = true;
    promise = this.http.put('/.resource/user/' + user.id + '?appid=' + this.app.id, update).then((function(_this) {
      return function(res) {
        user.loading = false;
        return angular.extend(user, update);
      };
    })(this), function() {
      return alert('Erro ao salvar roles');
    });
    return promise;
  };

  WebsiteSingle.prototype.deployRepository = function() {
    return this.http.post('/.resource/apps/deploy_repository?appid=' + this.app.id).then((function(_this) {
      return function(res) {
        return console.log('deploy_repository', res);
      };
    })(this), function() {
      console.log('deploy_repository error:', res);
      return alert('Erro ao salvar roles');
    });
  };

  return WebsiteSingle;

})());
