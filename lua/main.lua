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

local mainView = ui.Surface(
    ui.Bounds(0,1.5,0,   0.8, 0.5, 0.01)
        :rotate(-3.14/2, 0,1,0)
        :move(-5,0,2)
)
mainView:setColor({0.7,0.7,0.7,1})

mainView.grabbable = true

local heading = mainView:addSubview(ui.Label{
    bounds= ui.Bounds(0,0,0,  mainView.bounds.size.width, 0.05, 0.01),
    text= "Admin: "..app.client.placename,
    halign= "left"
})

local stack = nil
local admindata = nil
--  {
--      display_name= "Decorator",
--      is_visor= false,
--      connected_at= 1643407779.0,
--      agent_id= "123",
--      stats= "asdf"
--  }
function setAdminData(data)
    if admindata and data and tablex.deepcompare(data, admindata) then return end
    admindata = data

    if stack then stack:removeFromSuperview() end
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

    stack = mainView:addSubview(ui.StackView(ui.Bounds(0,-heading.bounds.size.height/2,0, w, dataHeight, 0.01), "vert"))
    stack:margin(rowMargin)
    for _, client in ipairs(data) do
        local row = stack:addSubview(ui.View(ui.Bounds(0,0,0, w, rowHeight, 0.01)))
        local label = row:addSubview(ui.Label{
            text= client.display_name,
            bounds= row.bounds:copy():insetEdges(0.1, 0, 0.01, 0.01, 0, 0),
            halign= "left"
        })
        local icon = row:addSubview(ui.Surface(
            row.bounds:copy():insetEdges(0.030, w-rowHeight-0.015, 0.01, 0.01, 0, 0.001)
        ))
        icon:setTexture(client.is_visor and assets.person or assets.app)
        local bW = 0.15
        local kickButton = row:addSubview(ui.Button(
            row.bounds:copy():insetEdges(w/1.3, 0.04, 0.01, 0.01, -0.02, 0.006)
        ))
        kickButton.label:setText(client.is_visor and "Kick" or "Quit")
        kickButton.onActivated = function()
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
                    ui.StandardAnimations.addFailureAnimation(kickButton, 0.03)
                    return
                end
                print("ok!")
                fetchAdminData()
            end)
        end
        local statsLabel = row:addSubview(ui.Label{
            bounds= row.bounds:copy():insetEdges(w/1.8, kickButton.bounds:getEdge("left"), 0.025, 0.024, -0.02, 0.006),
            wrap= true,
            text= client.stats,
            halign= "left"
        })
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

app.mainView = mainView

app:connect()
app:run()
