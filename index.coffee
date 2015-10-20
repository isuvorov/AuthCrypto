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
    decipher = crypto.createDecipher(@algorithm, password)
    dec = decipher.update(text, 'base64', 'utf8')
    dec += decipher.final('utf8')
    dec
  encryptObject: (object) ->
    @encryptString JSON.stringify(object)
  decryptObject: (token) ->
    console.log
    JSON.parse @decryptString(token)
  encrypt: (object) ->
    @encryptObject object
  decrypt: (token) ->
    @decryptObject token

  ###
    Sample Express-like controller req,res wrapper

    You can copy this and  paste & change in real controller



  ###
  findCreateUpdate: $$.findCreateUpdate
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

    @findCreateUpdate UserModel, userData, (err, user)->
#      return res.json {user}
      req.login user, (err) ->
        if redirect
          return res.redirect redirect
        else
          return res.json user


  gatewayResolve: (req, res)->

    if !req.user
      params = req.allParams()
      redirect = "/auth/gateway?" +
        Object.keys(params).filter (key)->
          typeof params[key] != "undefined"
        .map (key)->
          key + "=" + encodeURIComponent(params[key])
        .join("&")

      return res.redirect "/auth/login?redirect=" + encodeURIComponent(redirect)


    userData =
      id: req.user.id
      username: req.user.id + "@appberry.ru"
      name: req.user.getFullName()
      avatar: req.user.getAvatar()
      role: req.user.role || "user"
      platform: "appberry.ru"

    token = AuthCrypto.encrypt userData

  #  token = "Q3zn36OYixdKwICsuyrMrQXLTOGA7RMmkK83wE9Zu5DpVOrF9zlg2BNbw0DTfinm9rKn8uRDJJulBcN9EPUooDLu6gD1kWnaF1MaNDORxZcLAl3bU7YIdYB_c8s3OlOyZ2wQpVXMKHdAgkvzcXwtdcY2QmKzKfTzCWSzbbkWzw3b26P6c1zwZXPfPyX9h75TgyLYF6kb9cWlIAQAqAuhXQ98KsvXxhAkezkHRGNp7Txs5rfcvjq4C2YjZvrxcxwtjhnOp0gMMrZpBj0E6InNDjbmkJZ4wZmzjqkFJXlHKQ2iC-euHoeb7oxaNi-Nk8KMoA3PU3VBG-PU"
    return res.redirect req.param("redirect") + "&token=" +  token;
  gateway: (req, res, User)->


      url = req.protocol + '://' + req.host + "/auth/crypto?v=1&redirect=" + encodeURIComponent(req.url)
      return res.redirect req._sails.config.authcrypto.gateway + "?token=123&redirect=" + encodeURIComponent(url)

      return res.redirect2 {
        _url: req._sails.config.authcrypto.gateway,
        token: 123,
        redirect: {
          _url: req.protocol + '://' + req.host + "/auth/crypto",
          v: 1,
          redirect: req.url
        }
      }