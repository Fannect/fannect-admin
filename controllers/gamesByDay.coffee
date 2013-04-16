express = require "express"
mongoose = require "mongoose"
Team = require "../common/models/Team"
async = require "async"
dateFormat = require "../utils/date"
_ = require "underscore"
passport = require "passport"

app = module.exports = express()

app.get "/gamesbyday", passport.authenticate("basic", { session: false }), (req, res, next) ->
   date = if req.query.date then new Date(new Date(req.query.date)/1 + 3.6e6) else new Date()
   date = new Date()
   end_date = new Date(date/1 + 8.64e7)
   sport = req.query.sport

   async.parallel
      pregame: (done) ->
         Team
         .find({ "schedule.pregame.game_time": { $gte: date, $lte: end_date } })
         .sort("schedule.pregame.game_time full_name")
         .select("schedule.pregame full_name sport_name")
         .exec(done)
      postgame: (done) ->
         Team
         .find({ "schedule.postgame.game_time": { $gte: date, $lte: end_date } })
         .sort("schedule.postgame.game_time")
         .select("schedule.postgame full_name sport_name")
         .exec(done)
      season: (done) ->
         Team
         .aggregate { $match: { "schedule.season.game_time": { $gte: date, $lte: end_date } }}
         , { $unwind: "$schedule.season" }
         , { $match: { "schedule.season.game_time": { $gte: date, $lte: end_date } }}
         , done
   , (err, data) ->
      return res.render "error", error: err if err

      event_keys = []
      games = []

      processTeam = (team, field) ->
         game = team.schedule[field]
         return if game.event_key in event_keys
         return if sport and team.sport_name.toLowerCase() != sport.toLowerCase()

         event_keys.push(game.event_key)
         if process.env.NODE_ENV == "production"
            startTime = dateFormat(game.game_time/1+3.6e6, "shortTime")
         else
            startTime = dateFormat(game.game_time, "shortTime")
         games.push
            away: 
               id: if game.is_home then game.opponent_id else team._id
               name: if game.is_home then game.opponent else team.full_name
            home: 
               id: if game.is_home then team._id else game.opponent_id 
               name: if game.is_home then team.full_name else game.opponent
            event_key: game.event_key
            game_time: game.game_time
            start_time: startTime
            stadium: 
               location: game.stadium_location
               name: game.stadium_name

      if data.postgame?.length > 0
         processTeam(team, "postgame") for team in data.postgame
      if data.pregame?.length > 0
         processTeam(team, "pregame") for team in data.pregame
      if data.season?.length > 0
         processTeam(team, "season") for team in data.season

      res.render "gamesByDay",
         sport: sport or ""
         date: dateFormat(date, "yyyy-mm-dd")
         games: _.sortBy(games, (game) -> game.game_time / 1)
   
