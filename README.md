# AuthCrypto
Create json-based token, encrypt/decrypt token at other server

## Usage Example
```coffee

###
  Primary-Server
  server1.com
###
AuthCrypto = require "authcrypto"
AuthCrypto.password = "MySercretP@ssword"

HomeController =
  adminExampleAtServer2:
    userData =
      id: req.user.id
      username: req.user.id + "@server1.com"
      name: req.user.getFullName()
      avatar: req.user.getAvatar()
      role: req.user.role || "user"

    token = AuthCrypto.encrypt userData
    url = "http://server2.com/auth/crypto?redirect=/admin/example&token=" + token
    return res.redirect url

###
  Slave-Server
  server2.com
###
AuthCrypto = require "authcrypto"
AuthCrypto.password = "MySercretP@ssword"

AdminController =
  example:  (req, res) ->
    return res.badRequest {err: "auth"} if !req.user
    return res.json {secret:"information"}

AuthController =
  crypto: (req, res) ->
    converter = ()->
      return {
        id: rawData.username
        fullname: rawData.name
        image: rawData.avatar
        role: if rawData.role == 'root' then 'admin' : 'user'
      }
    AuthCrypto.controller req, res, User, converter
```