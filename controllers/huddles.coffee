express = require "express"
mongoose = require "mongoose"
Team = require "../common/models/Team"
Huddle = require "../common/models/Huddle"
async = require "async"
dateFormat = require "../utils/date"
passport = require "passport"
_ = require "underscore"

app = module.exports = express()

app.get "/huddles", passport.authenticate("basic", { session: false }), (req, res, next) ->
   async.parallel
      huddle_count: (done) -> Huddle.count({}, done)
      teams: (done) ->
         Huddle
         .aggregate { $group: {_id: "$team_id", name: { $first: "$team_name" }, posts: {"$sum": 1} } }
         , { $sort: { posts: -1 }}
         , done
   , (err, data) ->

      console.log data
      return res.render "error", error: err if err
      res.render "huddles", data: data
