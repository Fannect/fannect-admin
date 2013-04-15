rest = require "request"

global_config = null
access_token = null

fannect = module.exports = (config) -> 
   global_config =
      login_url: config.login_url or "http://localhost:2200"
      resource_url: config.resource_url or "http://localhost:2100"
      client_id: config.client_id
      client_secret: config.client_secret
   return fannect

fannect.request = (options, callback) ->
   if access_token == null
      return fannect.getAccessToken (err) ->
         return callback(err) if err
         fannect.request(options, callback)

   options.url = global_config.resource_url + options.url if options.url.indexOf("http") == -1
   options.qs = {} unless options.qs
   options.qs.access_token = access_token

   rest options, (err, resp, body) ->
      return callback(err) if err
      body = JSON.parse(body) if typeof(body) == "string"
      if resp.statusCode == 401 
         if not options.second_try
            options.second_try = true
            fannect.getAccessToken (err) ->
               return callback(err) if err
               fannect.request(options, callback)
         else  
            callback(new Error("Invalid credentials"))
      else
         callback(null, body)

fannect.getAccessToken = (callback) ->
   rest
      url: "#{global_config.login_url}/v1/apps/token"
      method: "POST"
      json: 
         client_id: global_config.client_id
         client_secret: global_config.client_secret
   , (err, resp, body) ->
      return callback(err) if err
      if body?.status == "fail"
         callback(body)
      else
         access_token = body.access_token
         callback(null, access_token)




