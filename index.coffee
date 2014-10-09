#                                                                              #
#                              Eatery server                                   #
#                                                                              #

express = require("express")
app     = express()
router  = express.Router()

config  = require("./config")
routes_calendar = require './routes_calendar'

#
# Set up the routes
#

## Home

router
  .route("/")
  .get (req, res) ->
    res.json message: "yo, welcome to our api!"
    return

## Calendars

router
  .route("/calendar")
  .get routes_calendar.all_ids

router
  .route("/calendar/:cal_id")
  .get routes_calendar.cal_id


## Locations

router
  .route("/location")
  .get (req, res) ->
    res.json( yo: 'whereup' )
    return

router
  .route("/location/:loc_id")
  .get (req, res) ->
    res.json( loc_id: req.params.loc_id )
    return

## Menus

router
  .route("/menu")
  .get (req, res) ->
    res.json( this_is: 'the_menu' )
    return

router
  .route("/menu/:menu_id")
  .get (req, res) ->
    res.json( menu_id: req.params.menu_id )
    return

router
  .route("/menu/:menu_id/:meal_type")
  .get (req, res) ->
    res.json
      menu_id: req.params.menu_id
      meal_type : req.params.meal_type
    return


### Good to go ###

#
# Start the server
#
app
  .use("/", router)
  .listen(config.port)

console.log("Good stuff happens on port " + config.port)