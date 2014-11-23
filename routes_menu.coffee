require './vendor/date_format'
cheerio = require 'cheerio'
request  = require 'request'
Promise  = require('es6-promise').Promise;

menu_locations = require('./menu_locations.json')

##
# @param date       A date object.
# 
# @param period     The meal to fetch.
#                    - Breakfast
#                    - Lunch
#                    - Dinner
#                    - Brunch
# 
# @param loc        An integer referring to a particular dining location, or a
#                   location id string 
#                    - Cook House Dining Room
#                    - Becker House Dining Room
#                    - Keeton House Dining Room
#                    - Rose House Dining Room
#                    - Hans Bethe – Jansen's Dining Room
#                    - Robert Purcell Marketplace Eatery
#                    - North Star
#                    - Risley Dining
#                    - 104 West!
#                    - Okenshields
get_menu = (date, period, loc, callback) ->

  if typeof loc_id = "string"
    loc = menu_locations[loc]

  request.post({
    uri: 'http://living.sas.cornell.edu/dine/whattoeat/menus.cfm',
    form: {
      menudates: date.format('yyyy-mm-dd')
      menuperiod: period
      menulocations: loc
    }
  }, (err, httpResp, body) ->

    if err 
      error = new Error()
      error.name = '503'
      throw error

    $ = cheerio.load(body)
    menuItems = []
    currentCategory = ''
    for sib in $('#menuform').siblings()
      continue unless $(sib).hasClass('menuCatHeader') || $(sib).hasClass('menuItem')
      if $(sib).hasClass('menuCatHeader')
        currentCategory = $(sib).text().trim()
        continue
      isHealthy = $(sib).children().length >= 1
      menuItems.push({
        name: $(sib).text().trim()
        category: currentCategory
        healthy: isHealthy
      })
    menuItems = null if menuItems.length is 0
    callback(menuItems, period, loc)
  )

today = ->
  return new Date()

module.exports.all_menus = (req, res) ->
  menu_data = {}
  meals = ['Breakfast', 'Lunch', 'Dinner', 'Brunch']
  locations = Object.keys(menu_locations)
  callbacksLeft = locations.length * meals.length
  
  renderIfDone = () ->
    callbacksLeft--
    return unless callbacksLeft <= 0
    res.json menu_data
  
  try 
    for menu_id in locations    # do: solves problems with nested forloops and 
      do(menu_id) ->            # closures within forloops. 
                               
        for meal in meals      
          do(meal) ->          
            
            get_menu(today(), meal, menu_id, (items) ->
              location = menu_data[menu_id]
              if location == undefined || location == null
                m = {}
                m[meal.toLowerCase()] = items
                menu_data[menu_id] = m
              else
                location[meal.toLowerCase()] = items
                menu_data[menu_id] = location
              renderIfDone()
            )

  catch e
    if e.name = '503'
      res.status(503).end()
    else
      res.status(500).end()

module.exports.menu_id = (req, res) ->
  menu_id = req.params.menu_id
  menu_list = {}
  t = today()

  if (Object.keys(menu_locations).indexOf(menu_id) < 0)
    res.status(404).json({error : "Invalid menu index"})
    return

  done1 = done2 = done3 = done4 = false
  renderIfDone = ->
    return unless done1 && done2 && done3 && done4
    res.json menu_list
  
  try 
    get_menu(t, 'Breakfast', menu_id, (items) ->
      menu_list['breakfast'] = items
      done1 = true
      renderIfDone()
    )
    get_menu(t, 'Lunch', menu_id, (items) ->
      menu_list['lunch'] = items
      done2 = true
      renderIfDone()
    )
    get_menu(t, 'Dinner', menu_id, (items) ->
      menu_list['dinner'] = items
      done3 = true
      renderIfDone()
    )
    get_menu(t, 'Brunch', menu_id, (items) ->
      menu_list['brunch'] = items
      done4 = true
      renderIfDone()
    )
  catch e 
    res.status(504).end()

module.exports.menu_for_meal = (req, res) ->
  meal_type_param = req.params.meal_type
  meal_type = meal_type_param.charAt(0).toUpperCase() + meal_type_param.slice(1)
  get_manu(today(), meal_type, req.params.menu_id, (items) ->
    res.json items
  )