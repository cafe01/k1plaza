var Websites;

backoffice.controller('Websites', Websites = (function() {
  Websites.$inject = ['$http'];

  function Websites(http) {
    this.http = http;
    console.log('Websites controller');
    this.websites = [];
    this.load();
  }

  Websites.prototype.load = function() {
    this.loading = true;
    return this.http.get('/.resource/apps').then((function(_this) {
      return function(res) {
        var item;
        _this.loading = false;
        if (res.data.success) {
          return _this.websites = (function() {
            var i, len, ref, results;
            ref = res.data.items;
            results = [];
            for (i = 0, len = ref.length; i < len; i++) {
              item = ref[i];
              item.created_at = moment(item.created_at);
              item.is_managed = parseInt(item.is_managed);
              results.push(item);
            }
            return results;
          })();
        }
      };
    })(this));
  };

  Websites.prototype.newApp = function() {
    this.newApp = {
      name: '',
      hostnames: [
        {
          name: null,
          environment: 'production'
        }
      ]
    };
    return this.showCreateApp = true;
  };

  Websites.prototype.newAppHostname = function() {
    return this.newApp.hostnames.push({
      name: null
    });
  };

  Websites.prototype.createApp = function() {
    var i, item, len, params, ref;
    params = {
      name: this.newApp.name,
      repository_url: this.newApp.repository_url,
      hostnames: []
    };
    ref = this.newApp.hostnames;
    for (i = 0, len = ref.length; i < len; i++) {
      item = ref[i];
      if (item.name != null) {
        params.hostnames.push(item);
      }
    }
    this.newAppError = false;
    return this.http.post('/.resource/apps', params).then((function(_this) {
      return function(res) {
        var app;
        app = res.data.items;
        app.hightlight = 'info';
        _this.websites.unshift(app);
        return _this.showCreateApp = false;
      };
    })(this), (function(_this) {
      return function(res) {
        return _this.newAppError = true;
      };
    })(this));
  };

  Websites.prototype.deployRepo = function() {
    this.loading = true;
    return this.http.get('/.resource/devops/update_repo').then((function(_this) {
      return function() {
        return _this.loading = false;
      };
    })(this), function() {
      this.loading = false;
      return alert("Erro!");
    });
  };

  return Websites;

})());
