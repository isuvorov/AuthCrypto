(function() {
  var $$, AuthCrypto, crypto;

  $$ = require('2dollars');

  crypto = require('crypto');

  module.exports = AuthCrypto = {
    algorithm: 'aes-256-ctr',
    password: 'CHANGE_THIS_PASSWORD_PLEASE-l9MB2tE3hTiI0W',
    encryptString: function(text, password) {
      var cipher, crypted;
      if (password == null) password = null;
      if (password === null) password = this.password;
      cipher = crypto.createCipher(algorithm, password);
      crypted = cipher.update(text, 'utf8', 'base64');
      crypted += cipher.final('base64');
      return $$.base64UrlEncode(crypted);
    },
    decryptString: function(text, password) {
      var dec, decipher;
      if (password == null) password = null;
      if (password === null) password = this.password;
      text = $$.base64UrlDecode(text);
      decipher = crypto.createDecipher(algorithm, password);
      dec = decipher.update(text, 'base64', 'utf8');
      dec += decipher.final('utf8');
      return dec;
    },
    encryptObject: function(object) {
      return this.encryptString(JSON.stringify(object));
    },
    decryptObject: function(token) {
      return JSON.parse(this.decryptString(token));
    },
    encrypt: function(object) {
      return this.encryptObject(object);
    },
    decrypt: function(token) {
      return this.decryptObject(token);
    },
    controller: function(req, res, UserModel, UserModelConvert) {
      var rawData, redirect, token, userData, v;
      if (UserModelConvert == null) UserModelConvert = null;
      if (UserModelConvert === null) {
        UserModelConvert = function(rawData) {
          var userData;
          userData = {
            id: rawData.username,
            name: rawData.name,
            avatar: rawData.avatar,
            role: rawData.role
          };
          return userData;
        };
      }
      token = req.param("token");
      redirect = req.param("redirect");
      if (!redirect) redirect = req.param("returnUrl");
      v = req.param("v");
      if (!v) {
        return res.serverError({
          err: "не указана версия"
        });
      }
      rawData = AuthCrypto.decrypt(token);
      if (!rawData) {
        return res.serverError({
          err: "не удалось расшифровать токен"
        });
      }
      userData = UserModelConvert(rawData);
      if (!rawData.id) {
        return res.serverError({
          err: "не удалось расшифровать ID в токене"
        });
      }
      return $$.findCreateUpdate(UserModel, userData, function(err, user) {
        return req.login(user, function(err) {
          if (redirect) {
            return res.redirect(redirect);
          } else {
            return res.json(user);
          }
        });
      });
    }
  };

}).call(this);
