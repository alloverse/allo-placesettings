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

local tileSize = 0.25

local root = ui.View(
    ui.Bounds(0,0.8,0,   0.8, 0.5, 0.01)
        :rotate(3.14/2, 0,1,0)
        
        :move(-2.8, 0, 0.42)
)

local manager = PlaceManager(app)
root:doWhenAwake(function()
    app:scheduleAction(1, true, function()
        manager:refresh()
    end)
end)


local dockView = root:addSubview(ui.StackView(
    ui.Bounds(0,0,0,   0.4, tileSize, 0.01)
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

local userDock = dockView:addSubview(ui.StackView(
    ui.Bounds(0,0,0, 0.4, tileSize, 0.01),
    "horizontal"
))
local appDock = dockView:addSubview(ui.StackView(
    ui.Bounds(0,0,0, 0.4, tileSize, 0.01),
    "horizontal"
))



class.AgentView(ui.Button.Cube)
function AgentView:_init(agent)
    self:super(ui.Bounds(0,0,0,  tileSize, tileSize, 0.10))
    self.agent = agent
    self.label.text = agent.display_name
    self.icon = self:addSubview(ui.Surface(self.bounds:copy()))
    self.icon:setTexture(agent.is_visor and assets.person or assets.app)
end

function AgentView:layout()
    ui.Button.Cube.layout(self)
    self.icon:setBounds(self.label.bounds:copy():insetEdges(0.05, 0.05, 0.00, 0.08, 0, 0))
    self.label.bounds:insetEdges(0,0, self.bounds.size.height*0.57, 0, 0, 0)
end

function AgentView:_pullUpDetails(details)
    if details.superview then return end
    

    details.transform = mat4.scale(mat4.new(), mat4.new(), vec3.new(0,0,0))
    self:addSubview(details)
    details:doWhenAwake(function()
        details:addPropertyAnimation(ui.PropertyAnimation{
            path= "transform.matrix",
            to= mat4.scale(mat4.new(), details.bounds.pose.transform, vec3.new(0,0,0)),
            from=   mat4.new(details.bounds.pose.transform),
            duration = 0.6,
            easing= "elasticOut"
        })
    end)
end

function AgentView:_pullDownDetails(details)
    if not details.superview then return end
    details:addPropertyAnimation(ui.PropertyAnimation{
        path= "transform.matrix",
        from= mat4.scale(mat4.new(), details.bounds.pose.transform, vec3.new(0,0,0)),
        to=   mat4.new(details.bounds.pose.transform),
        duration = 0.2,
        easing= "quadIn"
    })
    details.app:scheduleAction(0.2, false, function() 
        if details.superview then
            details:removeFromSuperview()
        end
    end)
end

class.AgentDetails(ui.Surface)
function AgentDetails:_init(agent)
    self:super(ui.Bounds(0,0,0,  0.3, 0.4, 0.01))
    self.agent = agent
    self.stack = self:addSubview(ui.StackView(self.bounds:copy():move(0,0,0.025), "vertical"))
    self.stats = self.stack:addSubview(ui.Label{
        wrap= true,
        halign= "left",
        bounds= ui.Bounds{size=ui.Size(0.3, 0.2, 0.01)},
        lineHeight= 0.03,
        color= {0,0,0,1},
    })
    self.goTo = self.stack:addSubview(ui.Button(ui.Bounds{size=ui.Size(0.3, 0.08, 0.05)}, "Go to"))
    self.goTo.onActivated = function(hand) 
        local avatar = hand:getAncestor()
        agent:teleportUser(avatar, function(ok)
            if not ok then
                ui.StandardAnimations.addFailureAnimation(self, 0.03)
            else
                self:pullDown()
            end
        end)
    end
    
    if agent.is_visor then
        self.ping = self.stack:addSubview(ui.Button(ui.Bounds{size=ui.Size(0.3, 0.08, 0.05)}, "Get attention"))
        self.ping.onActivated = function(hand) 
            local avatar = hand:getAncestor()
            agent:sendPingFrom(avatar, function(ok)
                if not ok then
                    ui.StandardAnimations.addFailureAnimation(self, 0.03)
                else
                    self:pullDown()
                end
            end)
        end
        self.kill = self.stack:addSubview(ui.Button(ui.Bounds{size=ui.Size(0.3, 0.08, 0.05)}, "Kick"))
    else
        self.quit = self.stack:addSubview(ui.Button(ui.Bounds{size=ui.Size(0.3, 0.08, 0.05)}, "Quit"))
        self.kill = self.stack:addSubview(ui.Button(ui.Bounds{size=ui.Size(0.3, 0.08, 0.05)}, "Force Quit"))
    end

    if self.quit ~= nil then
        self.quit.onActivated = function()
            agent:quit(function(ok)
                if not ok then
                    ui.StandardAnimations.addFailureAnimation(self, 0.03)
                else
                    manager:refresh()
                end
            end)
        end
    end
    self.kill.onActivated = function() 
        agent:kill(function(ok)
            if not ok then
                ui.StandardAnimations.addFailureAnimation(self, 0.03)
            else
                manager:refresh()
            end
        end)
    end

    self.bounds:move(0,0.5,0):rotate(3.14/8, 1,0,0)
    self:update()
    self:layout()
end

function AgentDetails:update()
    self.stats:setText("Stats for nerds:\n"..self.agent.stats)
end

function AgentDetails:layout()
    ui.Surface.layout(self)
    self.stack:layout()
    self.bounds.size = self.stack.bounds.size:copy():inset(-0.05, -0.05, 0)
    self:setBounds()
end

function AgentDetails:pullDown()
    self.superview:_pullDownDetails(self)
end

manager.onAgentAdded = function(agent)
    local button = AgentView(agent)
    agent.button = button;
    (agent.is_visor and userDock or appDock):addSubview(button)
    agent.details = AgentDetails(agent)

    button.onActivated = function(hand)
        if not agent.details.superview then
            button:_pullUpDetails(agent.details)
        else
            button:_pullDownDetails(agent.details)
        end
    end

    root:layout()
end

manager.onAgentUpdated = function(agent)
    agent.details:update()
end

manager.onAgentRemoved = function(agent)
    agent.button:removeFromSuperview()
    root:layout()
end

app.mainView = root

app:connect()
app:run()
