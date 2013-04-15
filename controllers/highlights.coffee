express = require "express"
mongoose = require "mongoose"
Highlight = require "../common/models/Highlight"
async = require "async"
dateFormat = require "../utils/date"
_ = require "underscore"
passport = require "passport"

app = module.exports = express()

app.get "/highlights", passport.authenticate("basic", { session: false }), (req, res, next) ->
   async.parallel
      total: (done) -> Highlight.count({}, done)
      active: (done) -> Highlight.count({ is_active: true }, done)
      total_breakdown: (done) ->
         Highlight
         .aggregate { $group: {_id: "$game_type", posts: { $sum: 1 }}}
         , $sort: { _id: 1 }
         , done
      active_breakdown: (done) -> 
         Highlight
         .aggregate { $match: { is_active: true }}
         , { $group: {_id: "$game_type", posts: { $sum: 1 }}}
         , $sort: { _id: 1 }
         , done
      teams: (done) ->
         Highlight
         .aggregate { $group: {_id: "$team_id", name: { $first: "$team_name" }, posts: {"$sum": 1} } }
         , { $sort: { posts: -1 }}
         , done
   , (err, data) ->
      return res.render "error", error: err if err
      res.render "highlights", data: data
