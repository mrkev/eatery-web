require './vendor/date_format'
cheerio = require 'cheerio'
request  = require 'request'
Promise  = require('es6-promise').Promise;

menu_locations = require('./menu_locations.json')

today = ->
  return new Date()

class MenuManager
  constructor: (@uri) ->
    @cache = {}


  populate_cache : () ->
    @all_menus().then(->
      return true
    )

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
  get_menu : (date, period, loc, should_refresh, callback) ->
    if typeof loc_id = "string"
      loc = menu_locations[loc]

    # http://stackoverflow.com/a/3894087/472768
    key = (period + date.setHours(0,0,0,0) + loc).replace(/\s/g, '')  # Remove all whitespace
    cachedMenu = @cache[key]
    unless cachedMenu == undefined || should_refresh
      callback(cachedMenu, period, loc)
      return
  
    request.post({
      uri: @uri,
      form: {
        menudates: date.format('yyyy-mm-dd')
        menuperiod: period
        menulocations: loc
      }
    }, ((err, httpResp, body) ->
            
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
      @cache[key] = menuItems
      if callback
        callback(menuItems, period, loc)
      else 

    ).bind(this))

  all_menus : () ->
    self = this
    return new Promise (resolve, reject) ->
      menu_data = {}
      meals = ['Breakfast', 'Lunch', 'Dinner', 'Brunch']
      locations = Object.keys(menu_locations)
      callbacksLeft = locations.length * meals.length
      
      renderIfDone = () ->
        callbacksLeft--
        return unless callbacksLeft <= 0
        resolve menu_data
      
      try 
        for menu_id in locations
          do(menu_id) ->

            for meal in meals
              do(meal) ->                
                self.get_menu(today(), meal, menu_id, false, (items) ->
                  console.log "Got #{meal} for #{menu_id}"

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
        reject e

  menu_id : (menu_id, should_refresh) ->
    self = this
    return new Promise (resolve, reject) ->
      menu_list = {}
      t = today()
  
      if (Object.keys(menu_locations).indexOf(menu_id) < 0)
        err = new Error()
        err.name = '404'
        err.message = 'Invalid menu index'
        reject err
  
      done1 = done2 = done3 = done4 = false
      renderIfDone = ->
        return unless done1 && done2 && done3 && done4
        resolve menu_list
      
      try 
        self.get_menu(t, 'Breakfast', menu_id, should_refresh, (items) ->
          menu_list['breakfast'] = items
          done1 = true
          renderIfDone()
        )
        self.get_menu(t, 'Lunch', menu_id, should_refresh, (items) ->
          menu_list['lunch'] = items
          done2 = true
          renderIfDone()
        )
        self.get_menu(t, 'Dinner', menu_id, should_refresh, (items) ->
          menu_list['dinner'] = items
          done3 = true
          renderIfDone()
        )
        self.get_menu(t, 'Brunch', menu_id, should_refresh, (items) ->
          menu_list['brunch'] = items
          done4 = true
          renderIfDone()
        )
      catch e
        res.status(504).end()

  menu_for_meal : (menu_id, meal_type) ->
    self = this
    return new Promise (resolve, reject) ->
      meal_type_param = meal_type
      meal_type = meal_type_param.charAt(0).toUpperCase() + meal_type_param.slice(1)
      self.get_menu(today(), meal_type, menu_id, resolve)

module.exports = new MenuManager('http://living.sas.cornell.edu/dine/whattoeat/menus.cfm')
