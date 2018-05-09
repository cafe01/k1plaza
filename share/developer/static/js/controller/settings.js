var Settings;

developer.controller('Settings', Settings = (function() {
  Settings.$inject = ['$http'];

  function Settings(http) {
    this.http = http;
    this.wizardPage = 0;
    this.http.get('/.dev/.resource/settings').then((function(_this) {
      return function(res) {
        _this.settings = res.data;
        _this.user = _this.settings.github_account;
        if (_this.settings.disable_autologin === void 0) {
          return _this.settings.disable_autologin = 0;
        }
      };
    })(this));
  }

  Settings.prototype.updateAccessToken = function(token) {
    var params;
    this.loading = true;
    params = angular.copy(this.settings);
    delete params.initial_setup;
    params.github_access_token = token;
    return this.http.post('/.dev/.resource/settings/token', {
      token: token
    }).then((function(_this) {
      return function(res) {
        return window.location = '/.dev/config';
      };
    })(this), (function(_this) {
      return function() {
        _this.loading = false;
        return alert("Token inválido.");
      };
    })(this));
  };

  Settings.prototype.save = function() {
    this.loading = true;
    return this.http.post('/.dev/.resource/settings', this.settings).then(function(res) {
      this.loading = false;
      return console.log("Settings saved!");
    });
  };

  Settings.prototype.resetSettings = function() {
    this.loading = true;
    return this.http.post('/.dev/.resource/settings', {}).then((function(_this) {
      return function(res) {
        return window.location = '/.dev/config';
      };
    })(this));
  };

  return Settings;

})());
