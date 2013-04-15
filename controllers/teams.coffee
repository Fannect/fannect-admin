express = require "express"
mongoose = require "mongoose"
Team = require "../common/models/Team"
Huddle = require "../common/models/Huddle"
Highlight = require "../common/models/Highlight"
TeamProfile = require "../common/models/TeamProfile"
async = require "async"
dateFormat = require "../utils/date"
_ = require "underscore"
passport = require "passport"
ObjectId = require("mongoose").Types.ObjectId

app = module.exports = express()

app.get "/teams/active", passport.authenticate("basic", { session: false }), (req, res, next) ->
   async.parallel
      teams: (done) ->
         TeamProfile
         .aggregate { $group: {_id: "$team_id", name: { $first: "$team_name" }, sport: { $first: "$sport_name"}, profiles: {$sum: 1}}}
         , { $sort: { profiles: -1 }}
         , done
      total_profiles: (done) -> TeamProfile.count({}, done)
   , (err, data) ->
      return res.render "error", error: err if err
      res.render "teams/active", data: data 
      
app.get "/teams/location", passport.authenticate("basic", { session: false }), (req, res, next) ->
   q = req.query.q
   return res.render "teams/location", data: { q: "", teams: [] } unless q

   Team.find { location_name: new RegExp(q, "i") }, "_id", (err, teams) ->
      return res.render "error", error: err if err
      ids = (team._id for team in teams)

      TeamProfile
      .aggregate { $match: { team_id: { $in: ids }}}
      , { $group: {_id: "$team_id", name: { $first: "$team_name" }, sport: { $first: "$sport_name"}, profiles: {$sum:1}}}
      , { $sort: { profiles: -1 }}
      , (err, teams) ->
         return res.render "error", error: err if err
         res.render "teams/location",
            data:
               q: req.query.q
               teams: teams

app.get "/teams/search", passport.authenticate("basic", { session: false }), (req, res, next) ->
   q = req.query.q
   return res.render "teams/search", data: { q: "", teams: [] } unless q

   TeamProfile
   .aggregate { $match: { team_name: new RegExp(q, "i") }}
   , { $group: {_id: "$team_id", name: { $first: "$team_name" }, sport: { $first: "$sport_name"}, profiles: {$sum:1}}}
   , { $sort: { profiles: -1 }}
   , (err, teams) ->
      return res.render "error", error: err if err
      res.render "teams/search",
         data:
            q: req.query.q
            teams: teams

app.get "/teams/:team_id", passport.authenticate("basic", { session: false }), (req, res, next) ->
   try
      team_id = new ObjectId(req.params.team_id)
   catch e
      return res.render "error", error: err if err
      
   async.parallel
      team: (done) -> Team.findById(team_id, "full_name sport_name", done)
      profile_count: (done) -> TeamProfile.count({ team_id: team_id }, done)
      highlight_total_count: (done) -> Highlight.count({ team_id: team_id }, done)
      highlight_active_count: (done) -> Highlight.count({ team_id: team_id, is_active: true }, done)
      highlight_total_breakdown: (done) ->
         Highlight
         .aggregate { $match: { team_id: team_id }}
         , { $group: {_id: "$game_type", posts: { $sum: 1 }} }
         , { $sort: { _id: 1 } }
         , done
      highlight_active_breakdown: (done) -> 
         Highlight
         .aggregate { $match: { is_active: true, team_id: team_id }}
         , { $group: {_id: "$game_type", posts: { $sum: 1 }} }
         , { $sort: { _id: 1 } }
         , done
      huddle_count: (done) -> Huddle.count({ team_id: team_id }, done)
   , (err, data) ->
      return res.render "error", error: err if err

      data.highlight_active_breakdown = [] unless data.highlight_active_breakdown
      data.highlight_total_breakdown = [] unless data.highlight_total_breakdown
      res.render "teams/team", data: data


