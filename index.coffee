#                                                                              #
#                              Eatery server                                   #
#                                                                              #

require('./newrelic')
express = require("express")
app     = express()
router  = express.Router()
timeout = require('connect-timeout')

config  = require("./config")
routes_calendar = require './routes_calendar'
routes_menu = require './routes_menu'
routes_location = require './routes_location'

#
# Set up the routes
#

## Home

router
  .route("/")
  .get (req, res) ->
    res.sendFile(__dirname + "/info.txt")
    return

## Calendars

router
  .route("/calendars")
  .get routes_calendar.all_ids

router
  .route("/calendar/:cal_id")
  .get routes_calendar.cal_id

router
  .route("/calendar/:cal_id/:start/:end")
  .get routes_calendar.render_range 

## Locations

# FIXME: Include GPS locations for each location
router
  .route("/locations")
  .get routes_location.all_locations

router
  .route("/location/:loc_id")
  .get routes_location.location

## Menus

router
  .route('/menus')
  .get routes_menu.all_menus
router
  .route("/menu/:menu_id")
  .get routes_menu.menu_id

router
  .route("/menu/:menu_id/:meal_type")
  .get routes_menu.menu_for_meal

router
  .route('/auth/groupme')
  .get (req, res) ->
     # res.send(req.query.access_token)
     res.redirect('cuappdevEatery://authorize?access_token=' + req.query.access_token)

router
  .route('/blank')
  .get (req, res) ->


### Good to go ###

#
# Start the server
#
port = if process.env.NODE_ENV == 'production' then process.env.PORT else 8080
app
  .use(timeout('10s'))
  .use("/", router)
  .use(haltOnTimedout)
  .listen(port)

`function haltOnTimedout(req, res, next){
  if (!req.timedout) 
    next();
  else
    res.status(408).end();
}`

console.log("Good stuff happens on port " + port)
