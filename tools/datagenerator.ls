require! 'mongoose'
require! 'moment'
{ argv } = require 'optimist'

{ Game }= require '../schema'
{ map } = require 'prelude-ls'

gamesPlayed = if argv.games != 'undefined' then argv.games else 1000
scoreSpread = if argv.scorespread != 'undefined' then argv.scorespread else 'basic'
gamesSpread = if argv.gamesspread != 'undefined' then argv.gamesspread else 'basic'
years = if argv.years != 'undefined' then argv.years else 5
mockNames = ['Oskari' 'Teemu' 'Niko' 'Tapio' 'Seppo', 'Jussi', 'Joni', 'Olli', 'Jari']

ready = 0

# Connect to mongo and start generating
mongodb_uri = process.env.MONGODB_URI || 'mongodb://localhost/kikkeri'
mongoose.connect mongodb_uri, ->
  game = generate 0
  game.save (err, res) ->
    whenReady 0, err, res

# callback, recursive saving
whenReady = (j, err, res)->
  if not err
    ready += 1
  else
    console.log(err)
    ready += 1
  if ready == gamesPlayed then
    console.log("All processed")
    process.exit()
  if ready % 500 == 0 then console.log "Saved " + ready + " and counting"
  game = generate j
  game.save (e, r) ->
    whenReady j + 1, e, r


generate = (ind) ->
  indexes = ((.length) mockNames)
  a_player = mockNames[Math.random() |> (*) indexes |> Math.floor]

#  First player in list plays more and more or less and less through time
  if gamesSpread != 'basic' then
    spread = (Math.random() + 0.5) < (i/gamesPlayed)
    if gamesSpread == 'more' && spread then
      a_player = mockNames[0];
    else if gamesSpread == 'less' && spread then
      while a_player == mockNames[0]
        a_player = mockNames[Math.random() |> (*) indexes |> Math.floor]

  b_player = mockNames[Math.random() |> (*) indexes |> Math.floor]
  while a_player == b_player
    b_player = mockNames[Math.random() |> (*) indexes |> Math.floor]
  a_score = Math.random()
  b_score = 0.5

#  First player in list gets better or worse through time
  if scoreSpread != 'basic' then
    if a_player == mockNames[0]
      if scoreSpread == 'ascend' then b_score -= b_score * (ind/gamesPlayed)
      else if scoreSpread == 'descend' then b_score += b_score * (ind/gamesPlayed)
    if b_player == mockNames[0]
      if scoreSpread == 'ascend' then
        b_score += b_score * (i/gamesPlayed)
      else if scoreSpread == 'descend' then
        b_score -= b_score * (i/gamesPlayed)

  if a_score >= b_score then
    a_score = 10
    b_score = Math.random() * 9 |> Math.floor
  else
    b_score = 10
    a_score = Math.random() * 9 |> Math.floor

  days = 365 * years * ((gamesPlayed - ind) / gamesPlayed) |> Math.floor
  game = new Game {
    teams:
      * players: a_player
        score: a_score
      * players: b_player
        score: b_score
    timestamp: moment().subtract({ 'days': days })
  }

