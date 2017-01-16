require! 'mongoose'

gameSchema = mongoose.Schema {
  teams: [{
    players: [String]
    score: Number
  }]
  timestamp: Date
  tags: [String]
}

module.exports.Game = mongoose.model 'Game', gameSchema
