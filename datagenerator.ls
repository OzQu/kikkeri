require! 'mongoose'
require! 'moment'

{ Game }= require '../schema'
{ map } = require 'prelude-ls'

gamesPlayed = 5000
mockNames = ['Oskari' 'Teemu' 'Niko' 'Tapio' 'Seppo']

mongodb_uri = process.env.MONGODB_URI || 'mongodb://localhost/kikkeri'
mongoose.connect mongodb_uri, ->
  ready = 0
  for i to gamesPlayed
    indexes = ((.length) mockNames)
    a_index = Math.random() |> (*) indexes |> Math.floor
    b_index = Math.random() |> (*) indexes |> Math.floor
    while a_index == b_index
      b_index = Math.random() |> (*) indexes |> Math.floor
    a_player = mockNames[a_index]
    b_player = mockNames[b_index]
    a_score = Math.random()
    b_score = 0.5
    if a_score >= b_score then
      a_score = 10
      b_score = Math.random() * 9 |> Math.floor
    else
      b_score = 10
      a_score = Math.random() * 9 |> Math.floor
    game = new Game {
      teams:
        * players: a_player
          score: a_score
        * players: b_player
          score: b_score
      timestamp: moment().subtract({ 'days': i })
    }

    game.save (err, res) ->
      if not err
        ready += 1
      else
        console.log(err)
        ready += 1
      if ready == gamesPlayed
        process.exit()
