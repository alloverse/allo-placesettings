local PlaceManager = require("placemanager")

local client = Client(
    arg[2], 
    "placesettings"
)

app = App(client)
assets = {
    quit = ui.Asset.File("images/quit.png"),
    app = ui.Asset.File("images/app.png"),
    person = ui.Asset.File("images/person.png"),
}
app.assetManager:add(assets)

local root = ui.View(
    ui.Bounds(0,0.8,0,   0.8, 0.5, 0.01)
        :rotate(3.14/2, 0,1,0)
        
        :move(-2.6, 0, 0.5)
)
root.grabbable = true

local manager = PlaceManager()
root:doWhenAwake(function()
    app:scheduleAction(1, true, function()
        manager:refresh()
    end)
end)


local dockView = root:addSubview(ui.StackView(
    ui.Bounds(0,0,0,   0.4, 0.4, 0.01)
        :rotate(-3.14/8, 1,0,0),
    "horizontal"
))

--local heading = dockView:addSubview(ui.Label{
--    bounds= ui.Bounds(0,-root.bounds.size.height/3,0,  dockView.bounds.size.width, 0.05, 0.01),
--    halign= "center",
--})
--heading:doWhenAwake(function()
--    heading:setText(app.client.placename)
--end)

local appDock = dockView:addSubview(ui.StackView(
    ui.Bounds(0,0,0, 0.4, 0.4, 0.01),
    "horizontal"
))
local userDock = dockView:addSubview(ui.StackView(
    ui.Bounds(0,0,0, 0.4, 0.4, 0.01),
    "horizontal"
))


class.AgentView(ui.Button)
function AgentView:_init(agent)
    self:super(ui.Bounds(0,0,0,  0.1, 0.15, 0.05))
    self.agent = agent
    self.label.text = agent.display_name
    self.defaultTexture = agent.is_visor and assets.person or assets.app
end

manager.onAppAdded = function(agent)
    local button = AgentView(agent)
    appDock:addSubview(button)
    dockView:layout()
end
manager.onUserAdded = function(agent)
    local button = AgentView(agent)
    userDock:addSubview(button)
    dockView:layout()
end

app.mainView = root

app:connect()
app:run()
