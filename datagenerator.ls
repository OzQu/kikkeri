require! 'mongoose'
require! 'moment'
{ argv } = require 'optimist'

{ Game }= require '../schema'
{ map } = require 'prelude-ls'

gamesPlayed = if argv.games != 'undefined' then argv.games else 1000
type = if argv.type != 'undefined' then argv.type else 'basic'
years = if argv.years != 'undefined' then argv.years else 5
mockNames = ['Oskari' 'Teemu' 'Niko' 'Tapio' 'Seppo', 'Jussi', 'Joni', 'Olli', 'Jari']

mongodb_uri = process.env.MONGODB_URI || 'mongodb://localhost/kikkeri'
mongoose.connect mongodb_uri, ->
  ready = 0
  for i to gamesPlayed
    switch type
    case 'ascend'
      game = changing i, true
    case 'descend'
      game = changing i, false
    case 'basic'
      fallthrough
    default
      game = basicGen i

    game.save (err, res) ->
      if not err
        ready += 1
      else
        console.log(err)
        ready += 1
      if ready == gamesPlayed
        process.exit()

basicGen = (i) ->
  indexes = ((.length) mockNames)
  a_player = mockNames[Math.random() |> (*) indexes |> Math.floor]
  b_player = mockNames[Math.random() |> (*) indexes |> Math.floor]
  while a_player == b_player
    b_player = mockNames[Math.random() |> (*) indexes |> Math.floor]
  a_score = Math.random()
  b_score = 0.5
  if a_score >= b_score then
    a_score = 10
    b_score = Math.random() * 9 |> Math.floor
  else
    b_score = 10
    a_score = Math.random() * 9 |> Math.floor
  days = 365 * years * (gamesPlayed/(i + 1)) |> Math.floor
  console.log years, i, gamesPlayed, days
  game = new Game {
    teams:
      * players: a_player
        score: a_score
      * players: b_player
        score: b_score
    timestamp: moment().subtract({ 'days': days })
  }

changing = (i, up) ->
  indexes = ((.length) mockNames)
  a_player = mockNames[Math.random() |> (*) indexes |> Math.floor]
  b_player = mockNames[Math.random() |> (*) indexes |> Math.floor]
  while a_player == b_player
    b_player = mockNames[Math.random() |> (*) indexes |> Math.floor]
  a_score = Math.random()
  b_score = 0.5
  if a_player == mockNames[0]
    if up then b_score -= b_score * (i/gamesPlayed)
    else b_score += b_score * (i/gamesPlayed)
  if b_player == mockNames[0]
    if up then
      b_score += b_score * (i/gamesPlayed)
    else
      b_score -= b_score * (i/gamesPlayed)
  if a_score >= b_score then
    a_score = 10
    b_score = Math.random() * 9 |> Math.floor
  else
    b_score = 10
    a_score = Math.random() * 9 |> Math.floor

  days = 365 * years * (gamesPlayed/(i + 1)) |> Math.floor
  console.log years, i, gamesPlayed, days
  game = new Game {
    teams:
      * players: a_player
        score: a_score
      * players: b_player
        score: b_score
    timestamp: moment().subtract({ 'days': days })
  }

