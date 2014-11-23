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
# @param loc        An integer referring to a particular dining location
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
menus = (date, period, loc, callback) ->
  request.post({
    uri: 'http://living.sas.cornell.edu/dine/whattoeat/menus.cfm',
    form: {
      menudates: date.format('yyyy-mm-dd')
      menuperiod: period
      menulocations: loc
    }
  }, (err, httpResp, body) ->
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
  callbacksLeft = 40
  renderIfDone = (key, meal) ->
    callbacksLeft--
    return unless callbacksLeft <= 0
    res.json menu_data
  locationNameForID = (id) ->
    for key in Object.keys(menu_locations)
      return key if menu_locations[key] == id
  for key in Object.keys(menu_locations)
    for meal in meals
      menu_id = menu_locations[key]
      menus(today(), meal, menu_id, (items, _meal, _key) ->
        locationName = locationNameForID(_key)
        console.log(locationName)
        location = menu_data[locationName]
        if location == undefined || location == null
          m = {}
          m[_meal.toLowerCase()] = items
          menu_data[locationName] = m
        else
          location[_meal.toLowerCase()] = items
          menu_data[locationName] = location
        renderIfDone(_key, _meal)
      )

module.exports.menu_id = (req, res) ->
  if (Object.keys(menu_locations).indexOf(req.params.menu_id) < 0)
    res.status(404).json({error : "Invalid menu index"})
    return

  menu_id = menu_locations[req.params.menu_id]
  menu_list = {}
  t = today()
  # Sorry … should probably use streams or promises
  done1 = done2 = done3 = done4 = false
  renderIfDone = ->
    return unless done1 && done2 && done3 && done4
    res.json menu_list
  menus(t, 'Breakfast', menu_id, (items) ->
    menu_list['breakfast'] = items
    done1 = true
    renderIfDone()
  )
  menus(t, 'Lunch', menu_id, (items) ->
    menu_list['lunch'] = items
    done2 = true
    renderIfDone()
  )
  menus(t, 'Dinner', menu_id, (items) ->
    menu_list['dinner'] = items
    done3 = true
    renderIfDone()
  )
  menus(t, 'Brunch', menu_id, (items) ->
    menu_list['brunch'] = items
    done4 = true
    renderIfDone()
  )

module.exports.menu_for_meal = (req, res) ->
  menu_id = menu_locations[req.params.menu_id]
  meal_type_param = req.params.meal_type
  meal_type = meal_type_param.charAt(0).toUpperCase() + meal_type_param.slice(1)
  menus(today(), meal_type, menu_id, (items) ->
    res.json items
  )