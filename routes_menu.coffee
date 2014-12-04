menu_manager = require './menu_manager'

today = ->
  return new Date()

module.exports.all_menus = (req, res) ->
  menu_manager.all_menus().then((menu_data) ->
    res.json menu_data
  
  ).catch((e)->
    if e.name = '503'
      res.status(503).end()
    else
      res.status(500).end()
  )

module.exports.menu_id = (req, res) ->
  refresh = req.query.refresh
  should_refresh = if typeof(refresh) == 'undefined' then false else if refresh == 'true' then true else false
  menu_manager.menu_id(req.params.menu_id, should_refresh).then((menu_data) ->
    res.json menu_data
  
  ).catch((e)->
    if e.name = '503'
      res.status(503).end()
    else
      res.status(500).end()
  )

module.exports.menu_for_meal = (req, res) ->
  meal_type_param = req.params.meal_type
  meal_type = meal_type_param.charAt(0).toUpperCase() + meal_type_param.slice(1)
  
  menu_manager.menu_for_meal(req.params.menu_id, meal_type).then((menu_data) ->
    res.json menu_data
  
  ).catch (e) ->
    if e.name = '503'
      res.status(503).end()
    else
      res.status(500).end()
  
