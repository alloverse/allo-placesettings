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

local admindata = {
    {
        display_name= "Decorator",
        is_visor= false,
        connected_at= 1643407779.0,
        agent_id= "123"
    },
    {
        display_name= "Marketplace",
        is_visor= false,
        connected_at= 1643407739.0,
        agent_id= "456"
    },
    {
        display_name= "Nevyn",
        is_visor= true,
        connected_at= 1643407830.0,
        agent_id= "789"
    },
}
local apps = tablex.filter(admindata, function(x) return not x.is_visor end )
local people = tablex.filter(admindata, function(x) return x.is_visor end )

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

local function setAdminData(data)
    if stack then stack:removeFromSuperview() end
    local c = #data
    local rowHeight = 0.06
    local rowMargin = 0.005
    local dataHeight = c*rowHeight
    local totalHeight = (rowHeight+rowMargin)*c + 0.08
    local w = mainView.bounds.size.width
    mainView.bounds.size.height = totalHeight
    mainView:markAsDirty("transform")

    heading.bounds:moveToOrigin():move(mainView.bounds.size:getEdge("top", "center")):move(0.03, -0.03, 0)
    heading:markAsDirty("transform")

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
            row.bounds:copy():insetEdges(w/1.4, 0.04, 0.01, 0.01, -0.02, 0.00)
        ))
        kickButton.label:setText(client.is_visor and "Kick" or "Quit")
    end
    stack:layout()
end

setAdminData(admindata)

app.mainView = mainView

app:connect()
app:run()
