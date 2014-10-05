iroh = require 'Iroh'

module.exports.all_ids = (req, res) ->
  iroh.query().then((data)->
      res.json data
      return
    )

module.exports.cal_id = (req, res) ->
  iroh.query(req.params.cal_id).then((data)->
      res.json data
      return
    )