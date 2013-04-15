express = require "express"
path = require "path"
mongoose = require "mongoose"
mongooseTypes = require "mongoose-types"
async = require "async"
dateFormat = require "../utils/date"
_ = require "underscore"
prettyCamel = require "pretty-camel"
passport = require "passport"
BasicStrategy = require("passport-http").BasicStrategy

mongoose.connect process.env.MONGO_URL or "mongodb://halloffamer:krzj2blW7674QGk3R1ll967LO41FG1gL2Kil@linus.mongohq.com:10045/fannect-dev"
# mongoose.connect process.env.MONGO_URL or "mongodb://halloffamer:krzj2blW7674QGk3R1ll967LO41FG1gL2Kil@fannect-production.member0.mongolayer.com:27017/fannect-production"
mongooseTypes.loadTypes mongoose

User = require "../common/models/User"
TeamProfile = require "../common/models/TeamProfile"

app = module.exports = express()

# Settings
app.set "view engine", "jade"
app.set "view options", layout: false
app.set "views", path.join __dirname, "../views"

app.configure "development", () ->
   app.use express.logger "dev"
   app.use express.errorHandler { dumpExceptions: true, showStack: true }

app.configure "production", () ->
   app.use express.errorHandler()

# Middleware
app.use express.query()
app.use express.bodyParser()
app.use require("connect-assets")()
app.use express.static path.join __dirname, "../public"
app.use prettyCamel.middleware
app.use passport.initialize()

# Security
passport.use new BasicStrategy (u, p, done) ->
   done null, (u.toLowerCase() == "fannect" and p == (process.env.PASSWORD or "BestAdminTool"))

# Routes
app.get "/", passport.authenticate("basic", { session: false }), (req, res, next) -> 
   async.parallel
      total_users: (done) -> User.count({}, done)
      total_profiles: (done) -> TeamProfile.count({}, done)
      twitter_users: (done) -> User.count({ twitter: { $exists: true, $ne: null}}, done)
      facebook_users: (done) -> User.count({ facebook: { $exists: true, $ne: null}}, done)
      instagram_users: (done) -> User.count({ instagram: { $exists: true, $ne: null}}, done)
      verified_users: (done) -> User.count({ verified: { $exists: true, $nin: [null, "fannect_squad"]}}, done)
   , (err, data) ->
      return res.render "error", error: err if err
      res.render "index", data: data

app.use require "./gamesByDay"
app.use require "./huddles"
app.use require "./highlights"
app.use require "./teams"


