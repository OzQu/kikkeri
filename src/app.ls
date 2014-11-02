require! 'express'
require! 'mongoose'
require! 'body-parser'
require! 'moment'
require! './config'
require! './table-view'

{empty, concat, filter, any, all, map} = require 'prelude-ls'

gameSchema = mongoose.Schema {
  teams: [{
    players: [String]
    score: Number
  }]
  timestamp: Date
  tags: [String]
}

Game = mongoose.model 'Game', gameSchema
mongoose.connect 'mongodb://localhost/kikkeri', ->
  app = do express
  app.use('/web', express.static (__dirname + '/web'))
  app.use(bodyParser.json {})
  app.locals.moment = moment
  app.set('views', __dirname + '/views')
  app.set('view engine', 'jade')

  app.get '/', (req, res) ->
    Game.find {}, null, {sort: {timestamp: -1}, limit: 5} (err, games) ->
      res.render 'index', {config: config, games: games}

  app.get '/charts/', (req, res) ->
    res.render 'charts', { config: config, query: req.query }

  app.get '/table/', (req, res) ->
    pipeline = req-to-game-aggregate-pipeline req
    Game.aggregate pipeline, (err, games) ->
      if err
        res.status(500).send {success: false, reason: err}
      else
        data = table-view.process-game-table-data games
        res.render 'table', { config: config, query: req.query, data: data }

  app.get '/game/', (req, res) ->
    format = req.accepts ['json', 'html']
    if not format
      res.status(500).send {success: false, reason: 'No suitable format available'}
      return

    pipeline = req-to-game-aggregate-pipeline req
    Game.aggregate pipeline, (err, games) ->
      if err
        res.status(500).send {success: false, reason: err}
      else if format == 'json'
        res.send games
      else if format == 'html'
        res.render 'games', {config: config, query: req.query, games: games}

  app.post '/game/', (req, res) ->
    game = new Game req.body
    validScore = (s) -> s <= 10 and s >= 0
    if not (all validScore . (.score), game.teams)
      res.status(500).send {success: false, reason: 'invalid score'}
      return

    game.timestamp = new Date()
    game.save (err) ->
      if not err?
        res.send {"success": true}
      else
        res.status(500).send {success: false, reason: err}


  app.get '/game/:id/edit/', (req, res) ->
    Game.findById (req.param 'id'), (err, game) ->
      if err
        res.status(500).send {success: false, reason: 'game not found'}
      else
        res.render 'editgame', {config: config, game: game}

  app.get '/game/:id/', (req, res) ->
    format = req.accepts ['json', 'html']
    if not format
      res.status(500).send {success: false, reason: 'No suitable format available'}
      return

    Game.findById (req.param 'id'), (err, game) ->
      if err
        res.status(500).send {success: false, reason: 'game not found'}
      else if format == 'json'
        res.send game
      else if format == 'html'
        res.render 'game', {config: config, game: game}

  app.put '/game/:id/', (req, res) ->
    Game.findById (req.param 'id'), (err, game) ->
      if err
        res.status(500).send {success: false, reason: 'game not found'}
      else
        game.teams = req.body.teams
        game.tags = req.body.tags
        game.save()
        res.send {success: true}

  app.listen 3000

function req-to-game-aggregate-pipeline(req)
  query-list = (p) -> if req.query[p] then req.query[p].split(/[, ]+/)

  criteria-game-tags = (tags) ->
    | not tags? or empty tags => []
    | otherwise => [{$match: {tags: {$in: tags}}}]

  criteria-players = (names) ->
    | not names? or empty names => []
    | otherwise => [{$match: {teams: {$elemMatch: {players: {$in: names}}}}}]

  criteria-num-players = (n) ->
    | not n > 0 => []
    | otherwise => [
      {$unwind: "$teams"}
      {$group: {
        _id: "$_id"
        number_of_players: {$sum: {$size: "$teams.players" }}
        teams: {$push: "$teams"}
        timestamp: {$first: "$timestamp"}
        tags: {$first: "$tags"}
      }}
      {$match: {number_of_players: n}}]


  gameTags = query-list 'gameTags'
  players = query-list 'players'
  numPlayers = parseInt req.query.numPlayers

  pipeline = concat [
    criteria-game-tags gameTags
    criteria-players players
    criteria-num-players numPlayers
  ]
  pipeline.push {$sort: {timestamp: -1}}
  return pipeline

