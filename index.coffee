$$ = require('2dollars')
crypto = require('crypto')

module.exports = AuthCrypto =
  algorithm: 'aes-256-ctr'
  password: 'CHANGE_THIS_PASSWORD_PLEASE-l9MB2tE3hTiI0W'
  encryptString: (text, password = null) ->
    if password == null
      password = @password

    cipher = crypto.createCipher(algorithm, password)
    crypted = cipher.update(text, 'utf8', 'base64')
    crypted += cipher.final('base64')
    #return  (crypted);
#    console.log crypted
    $$.base64UrlEncode crypted
  decryptString: (text, password = null) ->
    if password == null
      password = @password

    text = $$.base64UrlDecode(text)
    decipher = crypto.createDecipher(algorithm, password)
    dec = decipher.update(text, 'base64', 'utf8')
    dec += decipher.final('utf8')
    dec
  encryptObject: (object) ->
    @encryptString JSON.stringify(object)
  decryptObject: (token) ->
    JSON.parse @decryptString(token)
  encrypt: (object) ->
#    console.log {object}
    @encryptObject object
  decrypt: (token) ->
    @decryptObject token

  controller: (req, res, UserModel, UserModelConvert = null) ->
    if UserModelConvert == null
      UserModelConvert = (rawData)->
        userData =
          id: rawData.username
          name: rawData.name
          avatar: rawData.avatar
          role: rawData.role
        return userData
    token = req.param "token"
    redirect = req.param "redirect"
    if !redirect
      redirect = req.param "returnUrl"
    v = req.param "v"

    if !v
      return res.serverError {err: "не указана версия"}

    rawData = AuthCrypto.decrypt token
    if !rawData
      return res.serverError {err: "не удалось расшифровать токен"}

    userData = UserModelConvert rawData

    if !rawData.id
      return res.serverError {err: "не удалось расшифровать ID в токене"}

    $$.findCreateUpdate UserModel, userData, (err, user)->
#      return res.json {user}
      req.login user, (err) ->
        if redirect
          return res.redirect redirect
        else
          return res.json user

