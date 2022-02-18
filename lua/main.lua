local client = Client(
    arg[2], 
    "placesettings"
)

local app = App(client)
assets = {
    quit = ui.Asset.File("images/quit.png"),
    app = ui.Asset.File("images/app.png"),
    person = ui.Asset.File("images/person.png"),
}
app.assetManager:add(assets)

local root = ui.View(
    ui.Bounds(0,1.5,0,   0.8, 1, 0.01)
        :rotate(-3.14/2, 0,1,0)
        :move(-5,0,2)
)
root.grabbable = true

local mainView = root:addSubview(ui.Surface(
    ui.Bounds(0,0,0,   0.8, 0.5, 0.01)
))
mainView:setColor({0.7,0.7,0.7,1})

local heading = mainView:addSubview(ui.Label{
    bounds= ui.Bounds(0,0,0,  mainView.bounds.size.width, 0.05, 0.01),
    halign= "left"
})
heading:doWhenAwake(function()
    heading:setText("Admin: "..app.client.placename)
end)

local stack = nil
local admindata = nil
--  {
--      display_name= "Decorator",
--      is_visor= false,
--      connected_at= 1643407779.0,
--      agent_id= "123",
--      stats= "asdf"
--  }
local agentToRowMap = {}

function setAdminData(data)
    if admindata and data and tablex.deepcompare(data, admindata) then return end
    admindata = data

    local c = #data
    local rowHeight = 0.06
    local rowMargin = 0.005
    local dataHeight = c*rowHeight
    local totalHeight = (rowHeight+rowMargin)*c + 0.08
    local w = mainView.bounds.size.width
    mainView.bounds.size.height = totalHeight
    mainView:setBounds()

    heading.bounds:moveToOrigin():move(mainView.bounds.size:getEdge("top", "center")):move(0.03, -0.03, 0)
    heading:setBounds()

    local stackBounds = ui.Bounds(0,-heading.bounds.size.height/2,0, w, dataHeight, 0.01)
    if not stack then
        stack = mainView:addSubview(ui.StackView(stackBounds, "vert"))
        stack:margin(rowMargin)
    else
        stack:setBounds(stackBounds)
    end

    for _, client in ipairs(data) do
        local row = agentToRowMap[client.agent_id]
        if not row then
            row = stack:addSubview(ui.View())
            agentToRowMap[client.agent_id] = row
        end
        row:setBounds(ui.Bounds(0,0,0, w, rowHeight, 0.01))
        
        row.label = row.label and row.label or row:addSubview(ui.Label{
            halign= "left"
        })
        row.label:setBounds(row.bounds:copy():insetEdges(0.1, 0, 0.01, 0.01, 0, 0))
        row.label:setText(client.display_name)
        
        
        row.icon = row.icon and row.icon or row:addSubview(ui.Surface())
        row.icon:setBounds(row.bounds:copy():insetEdges(0.030, w-rowHeight-0.015, 0.01, 0.01, 0, 0.001))
        row.icon:setTexture(client.is_visor and assets.person or assets.app)
        
        row.kickButton = row.kickButton and row.kickButton or row:addSubview(ui.Button())
        row.kickButton:setBounds(row.bounds:copy():insetEdges(w/1.3, 0.04, 0.01, 0.01, -0.02, 0.006))
        
        row.kickButton.label:setText(client.is_visor and "Kick" or "Quit")
        row.kickButton.onActivated = function()
            print("kicking app", pretty.write(client))
            app.client:sendInteraction({
                sender_entity_id = mainView.entity.id,
                receiver_entity_id = "place",
                body = {
                    "kick_agent",
                    client.agent_id
                }
            }, function(resp, body)
                if body[2] ~= "ok" then
                    print("not kicking:", body[3])
                    ui.StandardAnimations.addFailureAnimation(row.kickButton, 0.03)
                    return
                end
                print("ok!")
                fetchAdminData()
            end)
        end
        row.statsLabel = row.statsLabel and row.statsLabel or row:addSubview(ui.Label{
            wrap= true,
            halign= "left"
        })
        row.statsLabel:setBounds(row.bounds:copy():insetEdges(w/1.8, row.kickButton.bounds:getEdge("left"), 0.025, 0.024, -0.02, 0.006))
        row.statsLabel:setText(client.stats)
    end

    for agent_id, row in pairs(agentToRowMap) do
        local found = false
        for _, client in ipairs(data) do
            if client.agent_id == agent_id then
                found = true
            end
        end
        if not found then
            row:removeFromSuperview()
            agentToRowMap[agent_id] = nil
        end
    end

    stack:layout()
end

function fetchAdminData()
    app.client:sendInteraction({
        sender_entity_id = mainView.entity.id,
        receiver_entity_id = "place",
        body = {
            "list_agents"
        }
    }, function(resp, body)
        if body[1] ~= "list_agents" and body[2] ~= "ok" then return end
        setAdminData(body[3])
    end)
end

setAdminData({})
mainView:doWhenAwake(function()
    app:scheduleAction(1, true, function()
        fetchAdminData()
    end)
    
end)

app.mainView = root

app:connect()
app:run()
